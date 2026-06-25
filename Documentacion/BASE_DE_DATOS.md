# BASE_DE_DATOS.md — PostgreSQL, Multitenancy y RLS

---

## 1. Estrategia Multitenancy

Existen tres patrones para multitenancy en bases de datos:

| Patrón | Descripción | Pros | Contras |
|--------|-------------|------|---------|
| **A) BD separada por tenant** | Cada cliente tiene su propia base de datos | Aislamiento total | Difícil de mantener a escala |
| **B) Schema separado por tenant** | Una BD, un schema por cliente | Buen aislamiento | Migraciones complejas (N schemas) |
| **C) Tabla compartida con `tenant_id`** | Una BD, tablas compartidas, RLS filtra | Escalable, fácil de mantener | Requiere RLS correcto — **elegido** |

### Decisión: Patrón C — tabla compartida con `tenant_id` + RLS

**Razón principal:** Con RLS de PostgreSQL, la seguridad vive en la base de datos misma. Aunque un bug en el código omitiera filtros, la BD nunca devuelve filas de otro tenant. Es el enfoque usado por Supabase, PostgREST y aplicaciones SaaS maduras.

---

## 2. Tabla `tenants` — Estructura Base

```sql
-- Tabla maestra de tenants (empresas cliente)
CREATE TABLE tenants (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug          VARCHAR(100) UNIQUE NOT NULL,   -- ej: "distribuidora-perez"
    nombre        VARCHAR(255) NOT NULL,
    rut           VARCHAR(20) UNIQUE,              -- RUT empresa (Chile)
    plan          VARCHAR(50) NOT NULL DEFAULT 'starter',  -- starter | pro | enterprise
    activo        BOOLEAN NOT NULL DEFAULT TRUE,
    config        JSONB NOT NULL DEFAULT '{}',     -- configuraciones por tenant
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 3. Row Level Security (RLS)

### Principio de funcionamiento

```
Usuario hace request → API Node.js valida JWT → extrae tenant_id
    → SET app.current_tenant = 'uuid-del-tenant'
    → ejecuta query
    → PostgreSQL aplica RLS automáticamente
    → solo devuelve filas donde tenant_id = current_tenant
```

### Implementación base

```sql
-- 1. Función para obtener el tenant del contexto de sesión
CREATE OR REPLACE FUNCTION current_tenant_id()
RETURNS UUID AS $$
    SELECT current_setting('app.current_tenant', TRUE)::UUID;
$$ LANGUAGE sql STABLE;

-- 2. Usuario de base de datos con permisos limitados (NO superuser)
CREATE ROLE app_user LOGIN PASSWORD 'password_seguro';
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- 3. Ejemplo en tabla productos
CREATE TABLE productos (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    codigo        VARCHAR(100) NOT NULL,
    nombre        VARCHAR(255) NOT NULL,
    descripcion   TEXT,
    unidad_medida VARCHAR(50) NOT NULL,  -- caja, unidad, kg, etc.
    precio_costo  NUMERIC(12,2),
    precio_venta  NUMERIC(12,2),
    activo        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, codigo)
);

-- 4. Habilitar RLS en la tabla
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

-- 5. Política: solo ver filas del tenant actual
CREATE POLICY tenant_isolation ON productos
    USING (tenant_id = current_tenant_id());

-- 6. Política separada para INSERT (el tenant_id se establece automáticamente)
CREATE POLICY tenant_insert ON productos
    FOR INSERT WITH CHECK (tenant_id = current_tenant_id());
```

### Cómo lo llama Node.js

```typescript
// En cada request autenticado, antes de cualquier query:
async function executeWithTenant<T>(
  tenantId: string,
  queryFn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query(`SET app.current_tenant = '${tenantId}'`);
    return await queryFn(client);
  } finally {
    client.release();
  }
}

// Uso:
const productos = await executeWithTenant(req.user.tenantId, async (client) => {
  return client.query('SELECT * FROM productos WHERE activo = true');
});
// RLS garantiza que solo devuelve productos de ese tenant
```

---

## 4. Esquema Completo de Tablas

### 4.1 Usuarios y Autenticación

```sql
CREATE TABLE usuarios (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    email         VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombre        VARCHAR(255) NOT NULL,
    apellido      VARCHAR(255),
    rol           VARCHAR(50) NOT NULL,   -- admin | vendedor | bodeguero | chofer | supervisor
    activo        BOOLEAN NOT NULL DEFAULT TRUE,
    ultimo_login  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, email)
);

ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON usuarios USING (tenant_id = current_tenant_id());
```

### 4.2 Bodegas e Inventario

```sql
CREATE TABLE bodegas (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    nombre        VARCHAR(255) NOT NULL,
    direccion     TEXT,
    responsable_id UUID REFERENCES usuarios(id),
    activo        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE bodegas ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON bodegas USING (tenant_id = current_tenant_id());

-- Stock por producto por bodega
CREATE TABLE inventario (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    bodega_id     UUID NOT NULL REFERENCES bodegas(id),
    producto_id   UUID NOT NULL REFERENCES productos(id),
    stock_actual  NUMERIC(12,3) NOT NULL DEFAULT 0,
    stock_minimo  NUMERIC(12,3) NOT NULL DEFAULT 0,
    stock_maximo  NUMERIC(12,3),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, bodega_id, producto_id)
);

ALTER TABLE inventario ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON inventario USING (tenant_id = current_tenant_id());

-- Todos los movimientos de inventario (entrada, salida, transferencia, ajuste)
CREATE TABLE movimientos_inventario (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    tipo            VARCHAR(50) NOT NULL,  -- entrada | salida | transferencia | ajuste
    bodega_origen   UUID REFERENCES bodegas(id),
    bodega_destino  UUID REFERENCES bodegas(id),
    producto_id     UUID NOT NULL REFERENCES productos(id),
    cantidad        NUMERIC(12,3) NOT NULL,
    referencia_tipo VARCHAR(50),   -- compra | venta | ajuste_manual | devolucion
    referencia_id   UUID,          -- ID del documento que originó el movimiento
    usuario_id      UUID NOT NULL REFERENCES usuarios(id),
    notas           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE movimientos_inventario ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON movimientos_inventario USING (tenant_id = current_tenant_id());
```

### 4.3 Clientes y Ventas

```sql
CREATE TABLE clientes (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    tipo          VARCHAR(20) NOT NULL DEFAULT 'empresa',  -- empresa | persona
    rut           VARCHAR(20),
    nombre        VARCHAR(255) NOT NULL,
    email         VARCHAR(255),
    telefono      VARCHAR(50),
    direccion     TEXT,
    comuna        VARCHAR(100),
    ciudad        VARCHAR(100),
    limite_credito NUMERIC(12,2) DEFAULT 0,
    dias_credito  INT DEFAULT 0,
    activo        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON clientes USING (tenant_id = current_tenant_id());

CREATE TABLE pedidos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    numero          SERIAL,   -- número legible por tenant (ver nota abajo)
    cliente_id      UUID NOT NULL REFERENCES clientes(id),
    vendedor_id     UUID REFERENCES usuarios(id),
    estado          VARCHAR(50) NOT NULL DEFAULT 'borrador',
    -- estados: borrador | confirmado | en_preparacion | en_reparto | entregado | cancelado
    fecha_pedido    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_entrega   DATE,
    subtotal        NUMERIC(12,2) NOT NULL DEFAULT 0,
    descuento       NUMERIC(12,2) NOT NULL DEFAULT 0,
    impuesto        NUMERIC(12,2) NOT NULL DEFAULT 0,
    total           NUMERIC(12,2) NOT NULL DEFAULT 0,
    notas           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON pedidos USING (tenant_id = current_tenant_id());

CREATE TABLE pedido_items (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    pedido_id     UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id   UUID NOT NULL REFERENCES productos(id),
    cantidad      NUMERIC(12,3) NOT NULL,
    precio_unit   NUMERIC(12,2) NOT NULL,
    descuento     NUMERIC(12,2) NOT NULL DEFAULT 0,
    subtotal      NUMERIC(12,2) NOT NULL
);

ALTER TABLE pedido_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON pedido_items USING (tenant_id = current_tenant_id());
```

### 4.4 Proveedores y Compras

```sql
CREATE TABLE proveedores (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    rut           VARCHAR(20),
    nombre        VARCHAR(255) NOT NULL,
    email         VARCHAR(255),
    telefono      VARCHAR(50),
    direccion     TEXT,
    activo        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE proveedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON proveedores USING (tenant_id = current_tenant_id());

CREATE TABLE ordenes_compra (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    proveedor_id    UUID NOT NULL REFERENCES proveedores(id),
    bodega_destino  UUID NOT NULL REFERENCES bodegas(id),
    comprador_id    UUID REFERENCES usuarios(id),
    estado          VARCHAR(50) NOT NULL DEFAULT 'borrador',
    -- estados: borrador | enviada | parcial | recibida | cancelada
    fecha_orden     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_esperada  DATE,
    total           NUMERIC(12,2) NOT NULL DEFAULT 0,
    notas           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE ordenes_compra ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON ordenes_compra USING (tenant_id = current_tenant_id());
```

### 4.5 Flota de Vehículos

```sql
CREATE TABLE vehiculos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    patente         VARCHAR(20) NOT NULL,
    marca           VARCHAR(100),
    modelo          VARCHAR(100),
    año             INT,
    capacidad_carga NUMERIC(10,2),  -- en kg o unidad definida por tenant
    estado          VARCHAR(50) NOT NULL DEFAULT 'activo',
    -- estados: activo | en_mantenimiento | fuera_de_servicio | baja
    proximo_mantenimiento DATE,
    kilometraje_actual    INT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, patente)
);

ALTER TABLE vehiculos ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON vehiculos USING (tenant_id = current_tenant_id());

CREATE TABLE rutas (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    pedido_id       UUID NOT NULL REFERENCES pedidos(id),
    vehiculo_id     UUID REFERENCES vehiculos(id),
    conductor_id    UUID REFERENCES usuarios(id),
    estado          VARCHAR(50) NOT NULL DEFAULT 'pendiente',
    -- estados: pendiente | en_curso | completada | fallida
    fecha_asignacion TIMESTAMPTZ,
    fecha_salida     TIMESTAMPTZ,
    fecha_entrega    TIMESTAMPTZ,
    notas_entrega    TEXT,
    firma_receptor   TEXT,   -- base64 de firma digital en móvil
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE rutas ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON rutas USING (tenant_id = current_tenant_id());
```

### 4.6 Empleados

```sql
CREATE TABLE empleados (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    usuario_id      UUID UNIQUE REFERENCES usuarios(id),  -- si tiene acceso al sistema
    rut             VARCHAR(20) NOT NULL,
    nombre          VARCHAR(255) NOT NULL,
    apellido        VARCHAR(255) NOT NULL,
    cargo           VARCHAR(100),
    departamento    VARCHAR(100),
    fecha_ingreso   DATE,
    salario_base    NUMERIC(10,2),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, rut)
);

ALTER TABLE empleados ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON empleados USING (tenant_id = current_tenant_id());
```

---

## 5. Numeración de Documentos por Tenant

Los pedidos necesitan números legibles (ej: "PED-00123") únicos **por tenant**, no globales.

```sql
-- Tabla de secuencias por tenant y tipo de documento
CREATE TABLE secuencias_documentos (
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    tipo          VARCHAR(50) NOT NULL,  -- pedido | compra | ajuste
    ultimo_numero INT NOT NULL DEFAULT 0,
    PRIMARY KEY(tenant_id, tipo)
);

-- Función para obtener y actualizar el número (atómica)
CREATE OR REPLACE FUNCTION next_document_number(p_tenant UUID, p_tipo VARCHAR)
RETURNS INT AS $$
DECLARE
    nuevo_numero INT;
BEGIN
    INSERT INTO secuencias_documentos (tenant_id, tipo, ultimo_numero)
    VALUES (p_tenant, p_tipo, 1)
    ON CONFLICT (tenant_id, tipo)
    DO UPDATE SET ultimo_numero = secuencias_documentos.ultimo_numero + 1
    RETURNING ultimo_numero INTO nuevo_numero;
    RETURN nuevo_numero;
END;
$$ LANGUAGE plpgsql;
```

---

## 6. Índices Críticos

```sql
-- Todos los tenant_id necesitan índices (las queries siempre filtran por tenant)
CREATE INDEX idx_productos_tenant ON productos(tenant_id);
CREATE INDEX idx_inventario_tenant_bodega ON inventario(tenant_id, bodega_id);
CREATE INDEX idx_inventario_stock_bajo ON inventario(tenant_id, producto_id)
    WHERE stock_actual <= stock_minimo;  -- índice parcial para alertas

CREATE INDEX idx_pedidos_tenant_estado ON pedidos(tenant_id, estado);
CREATE INDEX idx_pedidos_tenant_fecha ON pedidos(tenant_id, fecha_pedido DESC);
CREATE INDEX idx_pedidos_cliente ON pedidos(tenant_id, cliente_id);

CREATE INDEX idx_movimientos_tenant_fecha ON movimientos_inventario(tenant_id, created_at DESC);
CREATE INDEX idx_movimientos_referencia ON movimientos_inventario(tenant_id, referencia_tipo, referencia_id);

-- Búsqueda de texto en productos y clientes
CREATE INDEX idx_productos_nombre_trgm ON productos USING gin(nombre gin_trgm_ops);
CREATE INDEX idx_clientes_nombre_trgm ON clientes USING gin(nombre gin_trgm_ops);
```

---

## 7. Auditoría

Todas las operaciones críticas (crear, modificar, eliminar) se registran:

```sql
CREATE TABLE audit_log (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id     UUID NOT NULL REFERENCES tenants(id),
    usuario_id    UUID REFERENCES usuarios(id),
    tabla         VARCHAR(100) NOT NULL,
    operacion     VARCHAR(10) NOT NULL,  -- INSERT | UPDATE | DELETE
    registro_id   UUID NOT NULL,
    datos_antes   JSONB,
    datos_despues JSONB,
    ip_origen     INET,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Este log NO tiene RLS restrictivo — solo lectura para el tenant
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON audit_log USING (tenant_id = current_tenant_id());

-- Índice para consultas de auditoría
CREATE INDEX idx_audit_tenant_fecha ON audit_log(tenant_id, created_at DESC);
CREATE INDEX idx_audit_tabla_registro ON audit_log(tenant_id, tabla, registro_id);
```

---

## 8. Checklist de Seguridad BD

- [ ] PostgreSQL NO usa usuario `postgres` para la app (usar role dedicado `app_user`)
- [ ] `app_user` NO es superuser — no puede deshabilitar RLS
- [ ] RLS habilitado en **todas** las tablas con `tenant_id`
- [ ] Backups diarios automáticos con `pg_dump` encriptados
- [ ] Conexiones solo desde localhost o red interna (no exponer puerto 5432 a internet)
- [ ] SSL obligatorio en conexiones a la BD (`sslmode=require`)
- [ ] Passwords hasheados con `bcrypt` (factor 12) — nunca almacenar en texto plano
- [ ] Logs de queries lentas habilitados (`log_min_duration_statement = 1000`)

---

*Ver [MODULOS.md](./MODULOS.md) para la lógica de negocio de cada módulo.*
