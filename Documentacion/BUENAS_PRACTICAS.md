# BUENAS_PRACTICAS.md — Seguridad, Convenciones y CI/CD

---

## 1. Seguridad

### Autenticación y Sesiones
- Passwords hasheados con **bcrypt (factor 12)** — nunca MD5, SHA1 o texto plano
- JWT firmados con **RS256** (clave asimétrica), no HS256 (simétrica)
  - La clave privada solo vive en el servidor
  - Access Token: TTL 15 minutos
  - Refresh Token: TTL 7 días, rotado en cada uso
- Refresh Tokens almacenados en Redis, no en cookies ni localStorage
- Blacklist de tokens revocados en Redis hasta que expiren naturalmente

### Protección de API
- Rate limiting por tenant (no solo por IP)
- Headers de seguridad via Nginx:
  ```nginx
  add_header X-Frame-Options DENY;
  add_header X-Content-Type-Options nosniff;
  add_header Referrer-Policy no-referrer;
  add_header Content-Security-Policy "default-src 'self'";
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
  ```
- CORS configurado explícitamente — nunca `Access-Control-Allow-Origin: *` en producción
- Validación de input en **todas** las rutas con esquemas Zod (Node) / Pydantic (Python)
- SQL Injection: ver subsección dedicada más abajo

### SQL Injection

SQL Injection ocurre cuando input del usuario se concatena directamente en una query SQL, permitiendo que un atacante modifique la query y acceda o destruya datos. Es una de las vulnerabilidades más críticas y comunes en aplicaciones web.

**El problema — nunca hacer esto:**

```typescript
// ❌ VULNERABLE — el atacante controla lo que va dentro de la query
const nombre = req.body.nombre; // valor del usuario: "'; DROP TABLE productos; --"

const query = `SELECT * FROM productos WHERE nombre = '${nombre}'`;
// Query resultante:
// SELECT * FROM productos WHERE nombre = ''; DROP TABLE productos; --'
// Resultado: tabla productos eliminada
```

**La solución — queries parametrizadas siempre:**

```typescript
// ✅ SEGURO — el valor del usuario nunca forma parte de la query en sí
const { rows } = await client.query(
  'SELECT * FROM productos WHERE nombre = $1 AND tenant_id = $2',
  [req.body.nombre, req.user.tenantId]
  // PostgreSQL trata $1 y $2 como datos, nunca como SQL
);
```

**Con un query builder (Knex):**

```typescript
// ✅ SEGURO — Knex parametriza automáticamente
const productos = await db('productos')
  .where({ nombre: req.body.nombre, tenant_id: req.user.tenantId })
  .select('*');

// También seguro para búsqueda con LIKE
const resultados = await db('productos')
  .where('nombre', 'ilike', `%${req.body.buscar}%`) // Knex escapa automáticamente
  .where({ tenant_id: req.user.tenantId });
```

**Casos menos obvios donde también aplica:**

```typescript
// ❌ Ordenamiento dinámico — vulnerable si viene del usuario sin validar
const query = `SELECT * FROM pedidos ORDER BY ${req.query.orden}`;
// Atacante manda: orden = "id; DROP TABLE pedidos"

// ✅ Usar whitelist de columnas permitidas
const COLUMNAS_PERMITIDAS = ['fecha_pedido', 'total', 'estado', 'created_at'];
const columna = COLUMNAS_PERMITIDAS.includes(req.query.orden)
  ? req.query.orden
  : 'created_at'; // default seguro

const query = `SELECT * FROM pedidos ORDER BY ${columna}`; // seguro porque viene de whitelist
```

```typescript
// ❌ Búsqueda con IN() construida con string
const ids = req.body.ids.join(',');
const query = `SELECT * FROM productos WHERE id IN (${ids})`;

// ✅ Parametrizar con unnest (PostgreSQL)
const { rows } = await client.query(
  'SELECT * FROM productos WHERE id = ANY($1::uuid[])',
  [req.body.ids]
);
```

**Segunda línea de defensa — RLS de PostgreSQL:**

Aunque ocurra un SQL Injection, el RLS de PostgreSQL limita el daño al tenant actual. Un atacante autenticado como tenant A nunca podrá leer ni modificar datos del tenant B, incluso con una query maliciosa. Esto no reemplaza las queries parametrizadas — ambas defensas deben estar activas.

```
Atacante inyecta: ' OR '1'='1  (intento clásico de saltarse filtros)
→ La query maliciosa solo devuelve filas del tenant actual (RLS activo)
→ No puede ver datos de otros tenants
```

**Regla de oro:** si en algún punto del código ves un string de SQL construido con `+` o template literals que incluyen variables del usuario, es un bug de seguridad — reemplazarlo con parámetros inmediatamente.

### Datos Sensibles
- Variables de entorno en `.env` (nunca en el código)
- `.env` en `.gitignore` — nunca sube al repositorio
- Credenciales de producción en gestor de secretos (HashiCorp Vault o al menos variables del servidor)
- RUT y datos personales de empleados: acceso restringido por rol
- Logs nunca deben contener passwords, tokens o números de tarjeta

### Red y Servidor
- Puerto PostgreSQL (5432): solo accesible desde `localhost` o red interna Docker
- Puerto Redis (6379): solo accesible internamente
- Solo puertos 80 y 443 expuestos al exterior (via Nginx)
- SSH: autenticación por clave pública solamente, desactivar login por password
- Firewall (UFW): denegar todo por defecto, permitir solo 80, 443, SSH

---

## 2. Estructura del Monorepo

```
thoth/
├── apps/
│   ├── web/
│   │   ├── src/
│   │   │   ├── components/     → Componentes UI reutilizables
│   │   │   ├── pages/          → Una carpeta por módulo
│   │   │   ├── hooks/          → Custom hooks (useInventario, usePedidos)
│   │   │   ├── stores/         → Zustand stores (solo estado UI global)
│   │   │   ├── api/            → Funciones de llamada a API (TanStack Query)
│   │   │   └── utils/          → Utilidades puras (sin dependencias externas)
│   ├── mobile/                 → Flutter (Dart) — Android
│   │   ├── lib/
│   │   │   ├── screens/        → Pantallas de la app
│   │   │   ├── widgets/        → Componentes Flutter reutilizables
│   │   │   ├── providers/      → Riverpod providers (estado)
│   │   │   ├── services/       → Llamadas API (Dio) y lógica de negocio
│   │   │   ├── models/         → Clases Dart para los datos
│   │   │   └── utils/          → Utilidades (formateo, constantes)
│   │   └── pubspec.yaml        → Dependencias Flutter
│   ├── api-node/
│   │   ├── src/
│   │   │   ├── routes/         → Una carpeta por módulo (productos/, pedidos/, etc.)
│   │   │   ├── services/       → Lógica de negocio (separada de rutas)
│   │   │   ├── middleware/     → auth, rateLimiting, errorHandler
│   │   │   ├── plugins/        → Plugins Fastify (db, redis, cors)
│   │   │   └── types/          → Tipos TypeScript específicos de la API
│   └── api-python/
│       ├── app/
│       │   ├── routers/        → Endpoints FastAPI por módulo
│       │   ├── services/       → Lógica analytics y ML
│       │   ├── models/         → Modelos Pydantic
│       │   └── workers/        → Jobs de cola (BullMQ consumer)
├── packages/
│   ├── shared-types/           → Interfaces TypeScript compartidas
│   └── shared-utils/           → Funciones puras compartidas
├── db/
│   ├── migrations/             → 001_init.sql, 002_rls.sql, etc.
│   └── seeds/                  → Datos de prueba
└── docker-compose.yml
```

---

## 3. Convenciones de Código

### Nombres de archivos y carpetas
```
kebab-case para archivos y carpetas:
  inventario-service.ts
  pedido-item.model.ts
  uso-inventario.hook.ts

PascalCase para componentes React:
  ProductoCard.tsx
  PedidoDetalle.tsx

SCREAMING_SNAKE_CASE para constantes:
  MAX_ITEMS_POR_PAGINA = 100
  ESTADOS_PEDIDO = ['borrador', 'confirmado', ...]
```

### TypeScript — reglas importantes
```typescript
// ✅ Siempre tipar los retornos de funciones de servicio
async function getPedido(id: string): Promise<Pedido | null> { ... }

// ✅ Usar tipos discriminados para estados
type EstadoPedido = 'borrador' | 'confirmado' | 'en_preparacion' | 'entregado' | 'cancelado';

// ✅ Nunca usar `any`
// ❌ const data: any = await query()
// ✅ const data: Pedido = await query()

// ✅ Tipos compartidos en packages/shared-types
// Si un tipo se usa en web Y en api, va en shared-types
```

### SQL — convenciones
```sql
-- Nombres en snake_case
-- Tablas en plural: productos, pedidos, clientes
-- Columnas de timestamp: created_at, updated_at (con TIMESTAMPTZ, nunca TIMESTAMP)
-- Soft delete: columna activo BOOLEAN (nunca borrar registros con datos históricos)
-- PKs siempre UUID (nunca INT autoincrement — dificulta merges y migraciones)
-- Siempre incluir tenant_id + habilitar RLS en toda tabla con datos de negocio
```

---

## 4. Migraciones de Base de Datos

Usar archivos SQL numerados en `db/migrations/`:

```
001_init_tenants_usuarios.sql
002_rls_setup.sql
003_modulo_inventario.sql
004_modulo_ventas.sql
005_modulo_compras.sql
...
```

**Reglas:**
- Una migración nunca se modifica una vez aplicada en producción
- Para corregir algo, se crea una nueva migración
- Las migraciones se aplican en orden, una sola vez
- Usar una tabla `schema_migrations` para trackear qué migraciones se ejecutaron

```sql
CREATE TABLE schema_migrations (
    version     VARCHAR(50) PRIMARY KEY,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 5. Testing

### Pirámide de tests

```
        /\
       /  \     E2E tests (Playwright) — flujos críticos completos
      /----\
     /      \   Integration tests — endpoints + BD real (test container)
    /--------\
   /          \ Unit tests — servicios y funciones de negocio puras
  /____________\
```

### Qué testear obligatoriamente (mínimo viable)

**Unit tests (Jest / Vitest):**
- Cálculos de totales, descuentos, impuestos
- Validación de reglas de negocio (stock suficiente, crédito disponible)
- Funciones de transformación de datos para reportes

**Integration tests:**
- Flujo de crear pedido → validar stock → actualizar inventario
- Autenticación + RLS (verificar que tenant A no ve datos de tenant B)
- Endpoints de inventario (GET, POST, movimientos)

**E2E (cuando haya suficiente tiempo):**
- Login → crear pedido → confirmar → marcar entregado
- Crear compra → recibir → verificar que el inventario aumentó

---

## 6. CI/CD con GitHub Actions

### Pipeline básico (`.github/workflows/deploy.yml`)

```yaml
# Simplificado — ver archivo real en el repositorio
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - Checkout código
      - Instalar dependencias
      - Correr linter (ESLint + Prettier)
      - Correr type check (tsc --noEmit)
      - Correr unit tests
      - Correr integration tests (con PostgreSQL en container)

  deploy:
    needs: test  # Solo deploy si tests pasan
    runs-on: ubuntu-latest
    steps:
      - Build Docker images
      - Push a registro privado
      - SSH al servidor
      - docker-compose pull + up -d --no-downtime
      - Correr migraciones pendientes
      - Health check: esperar que la API responda /health
      - Notificar en Slack/Telegram si falla
```

### Ramas de Git

```
main          → producción (solo merge con PR aprobado)
develop       → integración continua (se despliega a staging)
feat/xxx      → features nuevas (branch desde develop)
fix/xxx       → correcciones (branch desde develop o main para hotfix)
```

---

## 7. Variables de Entorno

```bash
# .env.example (este SÍ va al repositorio como documentación)
# .env (este NUNCA va al repositorio)

# Base de datos
DATABASE_URL=postgresql://app_user:password@localhost:5432/thoth

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_PRIVATE_KEY=...   # Clave RS256 privada
JWT_PUBLIC_KEY=...    # Clave RS256 pública

# Servidor
PORT=3000
NODE_ENV=production

# Python analytics
PYTHON_SERVICE_URL=http://localhost:8000
PYTHON_SECRET_KEY=...  # Para autenticar Node → Python internamente

# Email (para notificaciones)
SMTP_HOST=...
SMTP_PORT=587
SMTP_USER=...
SMTP_PASS=...

# Sentry (monitoreo de errores)
SENTRY_DSN=...

# Futura integración SII
SII_AMBIENTE=certificacion  # certificacion | produccion
SII_RUT_EMPRESA=...
SII_CERTIFICADO_PATH=...
```

---

## 8. Checklist de Lanzamiento (Go-live)

### Seguridad
- [ ] Todas las rutas de API tienen autenticación (excepto /auth/login)
- [ ] RLS habilitado y verificado en todas las tablas
- [ ] SSL activo y redirige HTTP → HTTPS
- [ ] Headers de seguridad configurados en Nginx
- [ ] Variables de entorno verificadas (no hay valores de desarrollo en producción)
- [ ] Puerto BD y Redis no expuestos externamente

### Infraestructura
- [ ] Backups automáticos configurados y probados (hacer un restore de prueba)
- [ ] Monitoreo activo con alertas (CPU > 80%, disco > 70%, API down)
- [ ] Logs centralizados y accesibles
- [ ] Plan de rollback documentado (cómo volver a la versión anterior)

### Negocio
- [ ] Tenant inicial creado y configurado
- [ ] Usuario admin inicial creado con password seguro (no el default)
- [ ] Datos de prueba eliminados de producción
- [ ] Documentación básica para el usuario final

---

## 9. Idempotencia

Previene operaciones duplicadas cuando el usuario hace doble clic, la red falla y reintenta, o el cliente envía la misma request más de una vez.

El cliente genera un UUID único por cada **intención de operación** y lo manda en el header `Idempotency-Key`. Si el servidor recibe la misma key dos veces, devuelve el resultado de la primera sin reprocesar nada.

```
Primera request  → no existe en Redis → procesar → guardar resultado → responder
Segunda request  → existe en Redis    → devolver resultado guardado  → ignorar
```

**Reglas:**
- Generar la key **antes** del primer intento — nunca regenerarla en reintentos
- TTL de 24 horas en Redis (después de ese tiempo, se puede repetir la operación)
- Usar `NX: true` al guardar en Redis para evitar race conditions si dos requests llegan al mismo milisegundo

**Endpoints donde es obligatorio:**

| Endpoint | Riesgo sin idempotencia |
|----------|------------------------|
| `POST /pedidos` | Pedido duplicado |
| `POST /pedidos/:id/confirmar` | Stock descontado dos veces |
| `POST /inventario/movimiento` | Movimiento duplicado |
| `POST /compras/ordenes` | Orden duplicada al proveedor |
| `POST /compras/ordenes/:id/recibir` | Mercadería ingresada dos veces |
| `POST /flota/rutas` | Ruta duplicada al mismo conductor |

**No aplica en:** `GET *`, `PUT *`, `DELETE *`, `POST /auth/login`

> Ver implementación completa de código en [API.md](./API.md) · sección 8.

---

## 10. Seguridad Adicional

### CORS estricto

Nunca `Access-Control-Allow-Origin: *` en producción. Configurar lista blanca explícita:

```typescript
// plugins/cors.ts
fastify.register(cors, {
  origin: [
    'https://app.tudominio.cl',      // web producción
    'https://staging.tudominio.cl',  // staging
    // NO incluir localhost en producción
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key'],
  credentials: true,
});
```

### Helmet.js — headers de seguridad desde Node

Además de los headers en Nginx, agregar Helmet en Fastify como segunda capa:

```typescript
import helmet from '@fastify/helmet';

fastify.register(helmet, {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:'],
    },
  },
});
```

### Sanitización de inputs

Campos de texto libre (notas de pedidos, nombres, descripciones) pueden contener HTML malicioso. Sanitizar antes de guardar en BD:

```typescript
import DOMPurify from 'isomorphic-dompurify';

// En el schema de validación Zod
const notasSchema = z.string()
  .max(1000)
  .transform(val => DOMPurify.sanitize(val, { ALLOWED_TAGS: [] })); // sin tags HTML
```

### Validación de archivos subidos

Si se suben archivos (PDFs de facturas, imágenes de firma):

```typescript
// Nunca confiar en la extensión — verificar el magic number real del archivo
import { fileTypeFromBuffer } from 'file-type';

const tipo = await fileTypeFromBuffer(buffer);
const TIPOS_PERMITIDOS = ['application/pdf', 'image/png', 'image/jpeg'];

if (!tipo || !TIPOS_PERMITIDOS.includes(tipo.mime)) {
  throw new Error('Tipo de archivo no permitido');
}

// Límite de tamaño: 10 MB máximo
if (buffer.length > 10 * 1024 * 1024) {
  throw new Error('Archivo demasiado grande');
}
```

### Rotación de secrets sin downtime

Cuando se necesita cambiar JWT keys o passwords de BD:

```
1. Agregar la nueva key al servidor (sin remover la vieja)
2. Configurar la app para aceptar tokens firmados con AMBAS keys
3. Esperar que todos los tokens viejos expiren (máx. 15 min para access tokens)
4. Remover la key vieja
5. Revocar los refresh tokens activos — usuarios deben hacer login nuevamente
```

---

## 11. Base de Datos — Buenas Prácticas Adicionales

### Soft delete — comportamiento consistente

La columna `activo BOOLEAN` es el estándar para todos los registros. Reglas:

```
- Nunca hacer DELETE físico de registros con historial (productos, clientes, empleados)
- Al desactivar un producto: sus movimientos históricos se conservan intactos
- Al desactivar un cliente: sus pedidos históricos se conservan intactos
- Al desactivar un usuario: sus acciones en audit_log se conservan
- Las queries de listado siempre filtran WHERE activo = true por defecto
- Las queries de historial/reportes ignoran el filtro activo para ver todo
```

### Transacciones atómicas — cuándo son obligatorias

Estas operaciones DEBEN correr dentro de una transacción PostgreSQL. Si cualquier paso falla, todo se revierte:

```typescript
// Ejemplo: confirmar pedido (la operación más crítica)
await db.transaction(async (trx) => {
  // 1. Verificar stock de TODOS los ítems antes de descontar ninguno
  for (const item of pedido.items) {
    const stock = await trx('inventario')
      .where({ producto_id: item.producto_id, bodega_id: pedido.bodega_id })
      .first();

    if (stock.stock_actual < item.cantidad) {
      throw new Error(`Stock insuficiente: ${item.nombre}`);
    }
  }

  // 2. Descontar stock de todos los ítems
  for (const item of pedido.items) {
    await trx('inventario')
      .where({ producto_id: item.producto_id })
      .decrement('stock_actual', item.cantidad);

    await trx('movimientos_inventario').insert({ tipo: 'salida_venta', ... });
  }

  // 3. Actualizar estado del pedido
  await trx('pedidos').where({ id: pedido.id }).update({ estado: 'confirmado' });
});
// Si cualquier paso lanza error → todo se revierte automáticamente
```

**Operaciones que requieren transacción:**
- Confirmar pedido → descontar stock → registrar movimientos
- Recibir compra → aumentar stock → registrar movimientos
- Transferencia entre bodegas → salida de origen + entrada en destino
- Cancelar pedido confirmado → devolver stock

### Connection pooling

PostgreSQL tiene un límite de conexiones simultáneas. Sin pool, cada request abriría una conexión nueva y el servidor colapsaría bajo carga:

```typescript
// plugins/database.ts
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,              // máximo 20 conexiones simultáneas
  idleTimeoutMillis: 30000,   // cerrar conexiones inactivas después de 30s
  connectionTimeoutMillis: 2000, // error si no hay conexión disponible en 2s
});
```

> Para escala alta (Fase 2), considerar **PgBouncer** como proxy de conexiones entre Node y PostgreSQL. Permite cientos de clientes con pocas conexiones reales a la BD.

### Migraciones seguras — sin downtime

Nunca hacer cambios que bloqueen la tabla en producción:

```
✅ Agregar columna nullable:      ALTER TABLE productos ADD COLUMN peso NUMERIC;
✅ Agregar índice concurrente:    CREATE INDEX CONCURRENTLY idx_productos_nombre ON productos(nombre);
✅ Agregar tabla nueva:           CREATE TABLE nueva_tabla (...);

❌ Renombrar columna directamente (rompe el código en producción inmediatamente)
❌ Cambiar tipo de columna con datos (bloquea la tabla)
❌ DROP COLUMN sin verificar que el código ya no la usa

Patrón seguro para renombrar una columna:
  1. Agregar columna nueva con el nombre correcto
  2. Copiar datos de la columna vieja a la nueva
  3. Actualizar el código para usar la columna nueva
  4. Deploy del código nuevo
  5. En la siguiente migración: eliminar la columna vieja
```

---

## 12. API — Buenas Prácticas Adicionales

### Manejo global de errores

Un handler centralizado garantiza que ningún stack trace llegue al cliente en producción:

```typescript
// middleware/error-handler.ts
fastify.setErrorHandler((error, req, reply) => {
  // Log interno con todos los detalles
  req.log.error({
    error: error.message,
    stack: error.stack,
    requestId: req.id,
    tenantId: req.user?.tenantId,
    url: req.url,
  });

  // Errores de validación Zod → 400
  if (error.validation) {
    return reply.code(400).send({
      ok: false,
      error: { codigo: 'VALIDACION_FALLIDA', mensaje: 'Datos inválidos', detalles: error.validation }
    });
  }

  // Errores de negocio conocidos → 422
  if (error instanceof BusinessError) {
    return reply.code(422).send({
      ok: false,
      error: { codigo: error.codigo, mensaje: error.message }
    });
  }

  // Cualquier otro error → 500 genérico (nunca exponer detalles internos)
  return reply.code(500).send({
    ok: false,
    error: { codigo: 'ERROR_INTERNO', mensaje: 'Ocurrió un error. Intenta nuevamente.' }
  });
});
```

### Logging estructurado

Los logs deben ser JSON con campos consistentes para poder filtrarlos en Grafana/Loki:

```typescript
// Cada log debe incluir estos campos mínimos:
{
  "timestamp": "2026-06-28T15:30:00Z",
  "level": "info",
  "requestId": "uuid-de-la-request",
  "tenantId": "uuid-del-tenant",
  "userId": "uuid-del-usuario",
  "method": "POST",
  "url": "/api/v1/pedidos",
  "statusCode": 201,
  "duracionMs": 45,
  "mensaje": "Pedido creado exitosamente"
}

// NUNCA loggear:
// - passwords o tokens
// - números de tarjeta
// - datos personales sensibles (RUT, salarios)
```

### Request ID

Cada request recibe un ID único que se propaga en logs y en el header de respuesta. Permite rastrear un bug específico reportado por un usuario:

```typescript
fastify.addHook('onRequest', (req, reply, done) => {
  req.id = req.headers['x-request-id'] || crypto.randomUUID();
  reply.header('X-Request-ID', req.id);
  done();
});

// El usuario reporta un error → pide el X-Request-ID del navegador
// → buscas ese ID en los logs → encuentras exactamente qué pasó
```

### Timeouts

Sin timeouts, una query lenta puede bloquear workers y tumbar el servidor:

```typescript
// Timeout para queries de BD (5 segundos máximo)
const resultado = await Promise.race([
  db.query('SELECT ...'),
  new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Query timeout')), 5000)
  )
]);

// Timeout para llamadas Node → Python analytics (30 segundos — son más lentas)
const prediccion = await Promise.race([
  fetch(`${PYTHON_URL}/prediccion`),
  new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Analytics timeout')), 30000)
  )
]);
```

---

## 13. Frontend — Buenas Prácticas

### Token refresh transparente

El access token expira cada 15 minutos. Sin un interceptor, el usuario vería un error 401 y tendría que hacer login de nuevo. El interceptor lo renueva en silencio:

```typescript
// api/interceptor.ts (TanStack Query / axios)
async function fetchConRefresh(url: string, options: RequestInit) {
  let response = await fetch(url, {
    ...options,
    headers: { ...options.headers, Authorization: `Bearer ${getAccessToken()}` }
  });

  if (response.status === 401) {
    // Token expirado → renovar automáticamente
    const nuevoToken = await renovarToken();
    if (nuevoToken) {
      // Reintentar la request original con el token nuevo
      response = await fetch(url, {
        ...options,
        headers: { ...options.headers, Authorization: `Bearer ${nuevoToken}` }
      });
    } else {
      // Refresh token también expiró → redirigir al login
      redirigirAlLogin();
    }
  }

  return response;
}
```

### Optimistic UI

Mostrar el resultado esperado antes de que el servidor confirme, con rollback si falla. Hace la app sentirse instantánea:

```typescript
// Ejemplo: cambiar estado de entrega desde la app móvil
// (Flutter con Riverpod)

Future<void> marcarEntregado(String rutaId) async {
  // 1. Actualizar UI inmediatamente (optimistic)
  state = state.copyWith(rutas: state.rutas.map((r) =>
    r.id == rutaId ? r.copyWith(estado: 'entregado') : r
  ).toList());

  try {
    // 2. Confirmar en el servidor
    await api.put('/flota/rutas/$rutaId/estado', { estado: 'entregado' });
  } catch (e) {
    // 3. Si falla → revertir el estado visual
    state = state.copyWith(rutas: estadoAnterior);
    mostrarError('No se pudo actualizar. Intenta nuevamente.');
  }
}
```

---

## 14. Operaciones

### Health check endpoint

Endpoint que verifica el estado real de todos los servicios. Usado por Docker y CI/CD para saber si el deploy fue exitoso:

```typescript
// GET /health — no requiere autenticación
fastify.get('/health', async (req, reply) => {
  const checks = {
    api: 'ok',
    database: 'unknown',
    redis: 'unknown',
  };

  try {
    await db.query('SELECT 1');
    checks.database = 'ok';
  } catch {
    checks.database = 'error';
  }

  try {
    await redis.ping();
    checks.redis = 'ok';
  } catch {
    checks.redis = 'error';
  }

  const todoOk = Object.values(checks).every(v => v === 'ok');
  return reply.code(todoOk ? 200 : 503).send({ status: todoOk ? 'ok' : 'degraded', checks });
});
```

### Graceful shutdown

Cuando Docker reinicia un contenedor, dar tiempo a que las requests en curso terminen:

```typescript
// Al recibir señal de apagado (SIGTERM de Docker)
process.on('SIGTERM', async () => {
  console.log('Apagado iniciado — esperando requests en curso...');

  await fastify.close(); // deja de aceptar nuevas requests, espera las actuales
  await db.end();        // cierra el pool de conexiones limpiamente
  await redis.quit();    // cierra Redis limpiamente

  console.log('Apagado completado.');
  process.exit(0);
});
```

### Variables de entorno validadas al inicio

La app debe fallar inmediatamente si falta una variable crítica, no misteriosamente después:

```typescript
// config/env.ts — ejecutar al arrancar antes de cualquier otra cosa
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL:       z.string().url(),
  REDIS_URL:          z.string().url(),
  JWT_PRIVATE_KEY:    z.string().min(100),
  JWT_PUBLIC_KEY:     z.string().min(100),
  NODE_ENV:           z.enum(['development', 'staging', 'production']),
  PORT:               z.coerce.number().default(3000),
  PYTHON_SERVICE_URL: z.string().url(),
});

// Si falta algo → error claro al iniciar, no en producción
export const env = envSchema.parse(process.env);
// ❌ Error: DATABASE_URL: Required
// En lugar de: Cannot read properties of undefined (reading 'split') línea 847
```

---

## 15. Calidad de Código

### Husky + lint-staged

Corre linter y formatter automáticamente antes de cada commit. Código con errores no puede entrar al repositorio:

```bash
# Instalar
pnpm add -D husky lint-staged

# Configurar en package.json raíz
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}

# Activar el hook de git
npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

### Commits convencionales

Formato estándar para mensajes de commit. Permite generar changelogs automáticos y entender el historial:

```
feat:     nueva funcionalidad
fix:      corrección de bug
chore:    tareas de mantenimiento (deps, config)
docs:     cambios en documentación
refactor: refactorización sin cambio de funcionalidad
test:     agregar o corregir tests
perf:     mejora de rendimiento

Ejemplos:
  feat(ventas): agregar descuento por volumen en pedidos
  fix(inventario): corregir cálculo de stock en transferencias parciales
  chore(deps): actualizar Fastify a v5.1.0
  docs(api): documentar endpoint de idempotencia
```

### Manejo de zonas horarias

Toda fecha se almacena en UTC en la BD y se convierte a la zona horaria del usuario solo en el frontend:

```typescript
// ✅ En la BD: siempre TIMESTAMPTZ (UTC automático)
// created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()

// ✅ En el backend: nunca asumir zona horaria, trabajar siempre en UTC
const ahora = new Date(); // UTC

// ✅ En el frontend: convertir a zona horaria del tenant para mostrar
const fecha = new Date(pedido.created_at);
const fechaLocal = fecha.toLocaleString('es-CL', {
  timeZone: 'America/Santiago', // o la zona del tenant
  dateStyle: 'short',
  timeStyle: 'short',
});

// ❌ Nunca guardar fechas sin zona horaria en la BD
// ❌ Nunca asumir que el servidor y el cliente están en la misma zona horaria
```

> Chile tiene dos zonas horarias: `America/Santiago` (continental) y `Pacific/Easter` (Isla de Pascua). Si Thoth se expande, considerar guardar la zona horaria preferida por tenant en la tabla `tenants.config`.


---

## 16. Seguridad — Brute Force y OWASP

### Brute force en login

Fail2ban protege SSH, pero no los intentos de login a la aplicación. Un atacante puede intentar miles de passwords contra un email sin ser bloqueado a nivel de red. Solución en la propia API:

```typescript
// middleware/brute-force.ts
const MAX_INTENTOS = 5;
const BLOQUEO_MINUTOS = 15;

export async function verificarBruteForce(email: string, ip: string) {
  const keyEmail = `bf:email:${email}`;
  const keyIp = `bf:ip:${ip}`;

  const [intentosEmail, intentosIp] = await Promise.all([
    redis.get(keyEmail),
    redis.get(keyIp),
  ]);

  if (Number(intentosEmail) >= MAX_INTENTOS) {
    throw new BusinessError('CUENTA_BLOQUEADA',
      `Demasiados intentos fallidos. Intenta en ${BLOQUEO_MINUTOS} minutos.`);
  }

  if (Number(intentosIp) >= MAX_INTENTOS * 3) {
    throw new BusinessError('IP_BLOQUEADA',
      `Demasiadas solicitudes desde esta IP. Intenta más tarde.`);
  }
}

export async function registrarIntentoFallido(email: string, ip: string) {
  const keyEmail = `bf:email:${email}`;
  const keyIp = `bf:ip:${ip}`;
  const ttl = BLOQUEO_MINUTOS * 60;

  await Promise.all([
    redis.multi()
      .incr(keyEmail)
      .expire(keyEmail, ttl)
      .exec(),
    redis.multi()
      .incr(keyIp)
      .expire(keyIp, ttl)
      .exec(),
  ]);
}

export async function limpiarIntentos(email: string) {
  // Al hacer login exitoso, resetear el contador
  await redis.del(`bf:email:${email}`);
}
```

```typescript
// En la ruta POST /auth/login
fastify.post('/auth/login', async (req, reply) => {
  const { email, password } = req.body;
  const ip = req.ip;

  await verificarBruteForce(email, ip);      // ¿está bloqueado?

  const usuario = await buscarUsuario(email);
  const passwordOk = await bcrypt.compare(password, usuario?.password_hash ?? '');

  if (!usuario || !passwordOk) {
    await registrarIntentoFallido(email, ip); // incrementar contador
    throw new BusinessError('CREDENCIALES_INVALIDAS', 'Email o password incorrecto.');
  }

  await limpiarIntentos(email);              // login ok → resetear contador
  return generarTokens(usuario);
});
```

> **Nota de UX:** el mensaje de error es deliberadamente genérico ("Email o password incorrecto") — nunca especificar cuál de los dos falló, ya que eso le confirma al atacante que el email existe.

### OWASP Top 10 — Estado en Thoth

Referencia rápida de las 10 vulnerabilidades más comunes según OWASP y cómo Thoth las cubre:

| # | Vulnerabilidad | Estado en Thoth | Cómo |
|---|----------------|-----------------|------|
| A01 | Control de acceso roto | ✅ Cubierto | RLS en PostgreSQL + roles por módulo |
| A02 | Fallas criptográficas | ✅ Cubierto | bcrypt factor 12, JWT RS256, SSL obligatorio |
| A03 | Inyección (SQL, XSS) | ✅ Cubierto | Queries parametrizadas, Zod, DOMPurify |
| A04 | Diseño inseguro | ✅ Cubierto | Arquitectura multitenancy + RLS desde el diseño |
| A05 | Mala configuración | ✅ Cubierto | Helmet, headers Nginx, puertos cerrados, UFW |
| A06 | Componentes vulnerables | ⚠️ Parcial | npm audit manual — falta automatizar (ver sección 17) |
| A07 | Fallas de autenticación | ✅ Cubierto | Brute force, JWT con refresh rotation, blacklist |
| A08 | Fallas de integridad | ✅ Cubierto | CI/CD con tests, migraciones versionadas |
| A09 | Logging insuficiente | ✅ Cubierto | Logging estructurado, audit_log en BD, Sentry |
| A10 | SSRF | ⚠️ Vigilar | Si se agrega funcionalidad de webhooks o fetch de URLs externas |

### Dependency scanning

Revisar automáticamente si alguna librería instalada tiene vulnerabilidades conocidas:

```bash
# Node.js — auditar dependencias
npm audit
# o con pnpm:
pnpm audit

# Python — auditar dependencias
pip audit  # instalar con: pip install pip-audit

# Correr en CI/CD — agregar al pipeline de GitHub Actions:
- name: Auditar dependencias Node
  run: pnpm audit --audit-level=high  # falla solo en vulnerabilidades altas/críticas

- name: Auditar dependencias Python
  run: pip-audit --requirement requirements.txt
```

**Dependabot (GitHub):** agregar `.github/dependabot.yml` para que GitHub abra PRs automáticos cuando hay actualizaciones de seguridad:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/apps/api-node"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "pip"
    directory: "/apps/api-python"
    schedule:
      interval: "weekly"
```

---

## 17. Base de Datos — Índices, Vacuum y Restore

### Estrategia de índices

Un índice acelera las lecturas pero ralentiza las escrituras. Crear índices con criterio:

**Cuándo crear un índice:**
```sql
-- ✅ Columnas que aparecen frecuentemente en WHERE
CREATE INDEX idx_pedidos_estado ON pedidos(tenant_id, estado);

-- ✅ Columnas usadas en ORDER BY en queries frecuentes
CREATE INDEX idx_pedidos_fecha ON pedidos(tenant_id, fecha_pedido DESC);

-- ✅ Foreign keys que se usan en JOINs
CREATE INDEX idx_pedido_items_pedido ON pedido_items(pedido_id);

-- ✅ Búsqueda de texto (con pg_trgm)
CREATE INDEX idx_productos_nombre_trgm ON productos USING gin(nombre gin_trgm_ops);

-- ✅ Índice parcial para casos específicos frecuentes (muy eficiente)
CREATE INDEX idx_inventario_bajo_minimo ON inventario(tenant_id, producto_id)
  WHERE stock_actual <= stock_minimo;  -- solo indexa filas con stock bajo
```

**Cuándo NO crear un índice:**
```sql
-- ❌ Tablas pequeñas (< 1000 filas) — PostgreSQL hace full scan más rápido
-- ❌ Columnas con muy pocos valores distintos (ej: activo BOOLEAN en tabla con 80% true)
-- ❌ Columnas que casi nunca se usan en WHERE o JOIN
-- ❌ Índices duplicados (ya tienes uno que cubre lo mismo)
```

**Detectar queries lentas con EXPLAIN ANALYZE:**
```sql
-- Ver cómo PostgreSQL ejecuta una query y cuánto tarda
EXPLAIN ANALYZE
SELECT * FROM pedidos
WHERE tenant_id = 'uuid' AND estado = 'confirmado'
ORDER BY fecha_pedido DESC
LIMIT 25;

-- Buscar en la salida:
-- "Seq Scan" → recorre toda la tabla → probablemente necesita índice
-- "Index Scan" → usa índice → bien
-- "cost=" y "actual time=" → comparar para detectar cuellos de botella

-- Ver índices existentes en una tabla
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'pedidos';

-- Ver índices que nunca se usan (candidatos a eliminar)
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY tablename;
```

### Vacuum y mantenimiento PostgreSQL

PostgreSQL no elimina filas físicamente al hacer UPDATE o DELETE — las marca como "muertas" y las limpia después con VACUUM. Sin mantenimiento, la BD se degrada con el tiempo:

```sql
-- Ver estado de vacuum de cada tabla
SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Forzar vacuum manual en una tabla específica (si autovacuum no alcanza)
VACUUM ANALYZE pedidos;

-- Ver tamaño de tablas e índices
SELECT
  tablename,
  pg_size_pretty(pg_total_relation_size(tablename::regclass)) AS tamaño_total,
  pg_size_pretty(pg_relation_size(tablename::regclass)) AS tamaño_datos,
  pg_size_pretty(pg_indexes_size(tablename::regclass)) AS tamaño_indices
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(tablename::regclass) DESC;
```

**Configuración recomendada de autovacuum para tablas de alta escritura** (agregar a `postgresql.conf`):
```ini
autovacuum = on
autovacuum_vacuum_scale_factor = 0.05   # vacuum cuando 5% de filas están muertas (default 20%)
autovacuum_analyze_scale_factor = 0.02  # analyze cuando 2% cambia (default 10%)
log_min_duration_statement = 1000       # loggear queries que tarden más de 1 segundo
```

### Backup y Restore — procedimiento completo

El backup sin un restore probado no sirve. Probar el restore al menos una vez al mes:

```bash
# HACER BACKUP MANUAL
docker exec thoth-postgresql pg_dump \
  -U app_user \
  -d thoth \
  --format=custom \        # formato binario — más compacto y restaurable parcialmente
  --compress=9 \
  > /opt/thoth/backups/db/thoth_manual_$(date +%Y%m%d).dump

# VERIFICAR QUE EL BACKUP ES VÁLIDO
pg_restore --list /opt/thoth/backups/db/thoth_manual_20260628.dump | head -20
# Si muestra la lista de objetos → backup válido

# RESTAURAR EN BASE DE DATOS DE PRUEBA (hacer esto mensualmente)
# 1. Crear BD temporal
docker exec thoth-postgresql psql -U app_user -c "CREATE DATABASE thoth_restore_test;"

# 2. Restaurar el backup
docker exec -i thoth-postgresql pg_restore \
  -U app_user \
  -d thoth_restore_test \
  --no-owner \
  < /opt/thoth/backups/db/thoth_manual_20260628.dump

# 3. Verificar que los datos están correctos
docker exec thoth-postgresql psql -U app_user -d thoth_restore_test \
  -c "SELECT COUNT(*) FROM pedidos; SELECT COUNT(*) FROM productos;"

# 4. Limpiar
docker exec thoth-postgresql psql -U app_user -c "DROP DATABASE thoth_restore_test;"

# RESTAURAR EN PRODUCCIÓN (solo en emergencia real)
# ⚠️ Esto reemplaza TODOS los datos actuales
docker exec thoth-postgresql psql -U app_user -c "DROP DATABASE thoth; CREATE DATABASE thoth;"
docker exec -i thoth-postgresql pg_restore \
  -U app_user \
  -d thoth \
  --no-owner \
  < /opt/thoth/backups/db/thoth_manual_20260628.dump
```

---

## 18. API — Paginación con Cursor y Caché

### Paginación con cursor

La paginación por número de página (`?pagina=2&por_pagina=25`) tiene un problema: si alguien agrega o elimina registros entre páginas, el usuario ve duplicados o se saltea registros. Para listas que cambian en tiempo real (pedidos, movimientos de inventario), usar cursor-based pagination:

```typescript
// En lugar de: GET /pedidos?pagina=2
// Usar:        GET /pedidos?cursor=2026-06-28T15:30:00Z&por_pagina=25

// En el servicio:
async function getPedidosCursor(tenantId: string, cursor?: string, limite = 25) {
  const query = db('pedidos')
    .where({ tenant_id: tenantId, activo: true })
    .orderBy('created_at', 'desc')
    .limit(limite + 1); // pedir uno extra para saber si hay más

  if (cursor) {
    query.where('created_at', '<', new Date(cursor));
  }

  const pedidos = await query;
  const hayMas = pedidos.length > limite;
  if (hayMas) pedidos.pop(); // remover el extra

  return {
    data: pedidos,
    cursor_siguiente: hayMas ? pedidos[pedidos.length - 1].created_at : null,
    hay_mas: hayMas,
  };
}

// Respuesta:
{
  "ok": true,
  "data": [...],
  "cursor_siguiente": "2026-06-25T10:15:00Z",
  "hay_mas": true
}
// El cliente manda ese cursor en la siguiente request para obtener la página siguiente
```

**Cuándo usar cada tipo:**

| Tipo | Cuándo usar |
|------|-------------|
| Paginación por página | Reportes estáticos, exportaciones, tablas admin que no cambian en tiempo real |
| Paginación por cursor | Listas operacionales (pedidos, movimientos, rutas) que cambian constantemente |

### Caché de respuestas con Redis

No todas las respuestas necesitan ir a la BD en cada request. Algunos datos cambian poco y pueden cachearse:

```typescript
// middleware/cache.ts
export function cacheResponse(ttlSegundos: number) {
  return async (req: FastifyRequest, reply: FastifyReply) => {
    const cacheKey = `cache:${req.user.tenantId}:${req.url}`;

    const cached = await redis.get(cacheKey);
    if (cached) {
      reply.header('X-Cache', 'HIT');
      return reply.send(JSON.parse(cached));
    }

    // Guardar la respuesta en caché al enviarla
    reply.addHook('onSend', async (_, __, payload) => {
      if (reply.statusCode === 200) {
        await redis.setex(cacheKey, ttlSegundos, payload as string);
      }
    });

    reply.header('X-Cache', 'MISS');
  };
}

// Invalidar caché cuando los datos cambian
export async function invalidarCache(tenantId: string, patron: string) {
  const keys = await redis.keys(`cache:${tenantId}:${patron}*`);
  if (keys.length > 0) await redis.del(keys);
}
```

```typescript
// Uso en rutas:
fastify.get('/productos', { preHandler: cacheResponse(300) }, handler);
// GET /productos se cachea 5 minutos por tenant

fastify.post('/productos', async (req, reply) => {
  await crearProducto(req.body);
  await invalidarCache(req.user.tenantId, '/productos'); // invalidar al crear
  return reply.code(201).send({ ok: true });
});
```

**Qué cachear y por cuánto tiempo:**

| Endpoint | TTL | Razón |
|----------|-----|-------|
| `GET /productos` | 5 min | Catálogo cambia poco |
| `GET /clientes` | 2 min | Cambia ocasionalmente |
| `GET /flota/vehiculos` | 5 min | Cambia poco |
| `GET /reportes/kpis` | 1 min | Costoso de calcular, tolera leve retraso |
| `GET /pedidos` | ❌ No cachear | Cambia constantemente |
| `GET /inventario` | ❌ No cachear | Stock en tiempo real |

### Compresión de respuestas

Reducir el tamaño de respuestas JSON grandes (listados, reportes) con compresión Gzip/Brotli en Nginx:

```nginx
# En nginx.conf o en el bloque server de Thoth
gzip on;
gzip_vary on;
gzip_types application/json text/plain application/javascript text/css;
gzip_min_length 1024;   # solo comprimir respuestas > 1 KB
gzip_comp_level 6;      # nivel 6: buen balance velocidad/compresión

# Brotli (mejor compresión que gzip, soportado por navegadores modernos)
# Requiere módulo ngx_brotli — instalar si está disponible
brotli on;
brotli_types application/json text/plain;
brotli_comp_level 6;
```

> En respuestas JSON grandes (listados de 100+ pedidos, reportes de inventario), la compresión reduce el tamaño entre un 70–85%. El cliente lo descomprime automáticamente.

---

## 19. Multitenancy — Límites y Onboarding

### Límites por plan

Sin límites, un tenant en plan básico puede consumir recursos ilimitados y afectar a los demás. Controlar en la capa de API:

```sql
-- Agregar configuración de plan en la tabla tenants
ALTER TABLE tenants ADD COLUMN limites JSONB NOT NULL DEFAULT '{
  "max_usuarios": 5,
  "max_productos": 500,
  "max_bodegas": 2,
  "requests_por_hora": 1000
}';

-- Planes predefinidos
-- starter:    5 usuarios, 500 productos, 2 bodegas
-- pro:        20 usuarios, 5000 productos, 10 bodegas
-- enterprise: ilimitado
```

```typescript
// middleware/plan-limits.ts
export async function verificarLimitePlan(
  tenantId: string,
  recurso: 'usuarios' | 'productos' | 'bodegas'
) {
  const tenant = await db('tenants').where({ id: tenantId }).first();
  const limites = tenant.limites;
  const maxKey = `max_${recurso}` as keyof typeof limites;

  const conteo = await db(recurso)
    .where({ tenant_id: tenantId, activo: true })
    .count('id as total')
    .first();

  if (Number(conteo?.total) >= limites[maxKey]) {
    throw new BusinessError(
      'LIMITE_PLAN_ALCANZADO',
      `Has alcanzado el límite de ${limites[maxKey]} ${recurso} de tu plan. Actualiza tu plan para continuar.`
    );
  }
}

// Uso al crear un usuario nuevo:
fastify.post('/empleados', async (req, reply) => {
  await verificarLimitePlan(req.user.tenantId, 'usuarios');
  // ... crear usuario
});
```

### Onboarding de nuevo tenant

Flujo completo para registrar una nueva empresa en Thoth:

```typescript
// services/onboarding.ts
async function crearNuevoTenant(datos: {
  nombreEmpresa: string;
  rut: string;
  plan: string;
  adminNombre: string;
  adminEmail: string;
  adminPassword: string;
}) {
  return await db.transaction(async (trx) => {
    // 1. Crear el tenant
    const [tenant] = await trx('tenants').insert({
      nombre: datos.nombreEmpresa,
      rut: datos.rut,
      slug: generarSlug(datos.nombreEmpresa),
      plan: datos.plan,
      activo: true,
    }).returning('*');

    // 2. Crear usuario administrador inicial
    const passwordHash = await bcrypt.hash(datos.adminPassword, 12);
    const [usuario] = await trx('usuarios').insert({
      tenant_id: tenant.id,
      email: datos.adminEmail,
      password_hash: passwordHash,
      nombre: datos.adminNombre,
      rol: 'admin',
      activo: true,
    }).returning('*');

    // 3. Crear bodega principal por defecto
    await trx('bodegas').insert({
      tenant_id: tenant.id,
      nombre: 'Bodega Principal',
      responsable_id: usuario.id,
      activo: true,
    });

    // 4. Inicializar secuencias de documentos
    await trx('secuencias_documentos').insert([
      { tenant_id: tenant.id, tipo: 'pedido', ultimo_numero: 0 },
      { tenant_id: tenant.id, tipo: 'compra', ultimo_numero: 0 },
    ]);

    // 5. Enviar email de bienvenida
    await enviarEmailBienvenida(datos.adminEmail, datos.adminNombre, tenant.slug);

    return { tenant, usuario };
  });
}
```

---

## 20. Monitoreo — Alertas y Runbook

### Alertas específicas

No solo alertar por CPU alta — estas son las métricas críticas para Thoth:

```yaml
# Configuración de alertas en Prometheus/Grafana (pseudo-código)

alertas:
  # Infraestructura
  - nombre: CPU_ALTA
    condicion: cpu_uso > 80% por 5 minutos
    severidad: warning

  - nombre: DISCO_LLENO
    condicion: disco_libre < 20%
    severidad: critical   # puede detener PostgreSQL

  - nombre: RAM_ALTA
    condicion: ram_uso > 85% por 5 minutos
    severidad: warning

  - nombre: API_CAIDA
    condicion: health_check falla 3 veces seguidas
    severidad: critical

  # Aplicación
  - nombre: ERRORES_5XX
    condicion: tasa de errores 500 > 1% por 2 minutos
    severidad: warning

  - nombre: QUERIES_LENTAS
    condicion: query PostgreSQL > 5 segundos
    severidad: warning

  - nombre: REDIS_MEMORIA
    condicion: Redis usa > 80% de memoria configurada
    severidad: warning

  # Negocio
  - nombre: BACKUP_FALLIDO
    condicion: último backup exitoso hace > 25 horas
    severidad: critical

  - nombre: CONEXIONES_BD_ALTAS
    condicion: conexiones activas PostgreSQL > 18 (de máx 20)
    severidad: warning
```

**Dónde recibir las alertas:**
```
Telegram bot  → alertas críticas (inmediato, cualquier hora)
Email         → alertas warning (resumen diario)
```

### Runbook — Diagnóstico y recuperación

Guía paso a paso de qué hacer cuando algo falla. Seguir en orden:

---

#### La API no responde

```bash
# 1. Verificar que los contenedores están corriendo
docker ps
# ¿Está api-node en la lista? Si no → ir al paso 2
# ¿Está en la lista pero no responde? → ir al paso 3

# 2. El contenedor está caído — revisar por qué
docker logs thoth-api-node --tail 50
# Leer el error, buscar la causa, corregir y levantar:
docker compose up -d api-node

# 3. El contenedor corre pero no responde — revisar salud
curl http://localhost:3000/health
docker stats thoth-api-node  # ¿está usando 100% CPU?

# 4. Si el problema es memoria — reiniciar el contenedor
docker compose restart api-node

# 5. Si nada funciona — revisar logs completos y Sentry
docker logs thoth-api-node --since 1h
# Abrir Sentry → ver errores recientes
```

---

#### PostgreSQL no responde

```bash
# 1. Verificar que el contenedor corre
docker ps | grep postgresql

# 2. Ver logs de PostgreSQL
docker logs thoth-postgresql --tail 50
# Errores comunes:
# "could not write to file" → disco lleno → liberar espacio
# "too many connections" → pool agotado → ver sección connection pooling
# "out of memory" → aumentar RAM del servidor

# 3. Verificar espacio en disco (causa más común)
df -h
du -sh /opt/thoth/data/postgres/

# 4. Conectarse directamente para diagnóstico
docker exec -it thoth-postgresql psql -U app_user -d thoth
\l          -- listar bases de datos
\dt         -- listar tablas
SELECT COUNT(*) FROM pedidos;  -- verificar que los datos están

# 5. Si el contenedor no inicia — restaurar desde backup
# Ver sección Backup y Restore en sección 17
```

---

#### Disco lleno

```bash
# 1. Ver qué está ocupando el espacio
df -h                          # espacio por partición
du -sh /opt/thoth/*            # por carpeta de Thoth
du -sh /var/lib/docker/*       # logs y capas de Docker

# 2. Limpiar logs de Docker acumulados
docker system prune -f         # elimina contenedores/imágenes sin usar
docker volume prune -f         # ojo: no elimina volúmenes con datos

# 3. Limpiar backups viejos (si el crontab falló y acumuló)
ls -lh /opt/thoth/backups/db/
find /opt/thoth/backups/db/ -name "*.dump" -mtime +30 -delete

# 4. Limpiar logs del sistema
sudo journalctl --vacuum-time=7d   # conservar solo últimos 7 días
```

---

#### Error masivo de usuarios — cómo diagnosticar

```bash
# Un usuario reporta un error → pedirle el X-Request-ID del navegador
# (visible en las DevTools → Network → Headers de respuesta)

# Buscar ese ID en los logs
docker logs thoth-api-node --since 2h | grep "REQUEST-ID-AQUI"

# Ver el error completo con contexto
docker logs thoth-api-node 2>&1 | grep -A 20 "REQUEST-ID-AQUI"

# Buscar en Sentry por el mismo ID para ver el stack trace completo
```

---

## 21. Desarrollo — ADR, Seeds y Dependencias

### Architecture Decision Records (ADR)

Cada decisión técnica importante se documenta en un archivo corto. En 6 meses cuando no recuerdes por qué hiciste algo de cierta forma, el ADR lo explica:

```
db/
└── adr/
    ├── 001_postgresql_sobre_mysql.md
    ├── 002_multitenancy_rls.md
    ├── 003_flutter_sobre_react_native.md
    ├── 004_fastify_sobre_express.md
    └── 005_prophet_para_forecasting.md
```

Formato de cada ADR:

```markdown
# ADR-001: PostgreSQL sobre MySQL

## Fecha
2026-06-28

## Estado
Aceptado

## Contexto
Necesitamos una base de datos relacional para el sistema ERP multitenancy de Thoth.
Se evaluaron PostgreSQL 16 y MySQL 8.

## Decisión
Usar PostgreSQL 16.

## Razones
- Row Level Security (RLS) nativo — MySQL no lo tiene
- Window functions completas para analytics
- JSONB con operadores avanzados para configuración de tenants
- Extensiones disponibles (pg_trgm para búsqueda, TimescaleDB futuro)

## Consecuencias
- Los desarrolladores necesitan conocer PostgreSQL específicamente
- Sintaxis SQL ligeramente diferente a MySQL en algunos casos
- Mayor soporte para las funcionalidades que Thoth necesita
```

### Seeds — datos de prueba realistas

Nunca usar datos reales de producción en desarrollo. Generar datos sintéticos pero realistas:

```typescript
// db/seeds/001_tenant_demo.ts
import { faker } from '@faker-js/faker/locale/es';

export async function seed(db: Knex) {
  // Tenant de prueba
  const [tenant] = await db('tenants').insert({
    nombre: 'Distribuidora Demo SpA',
    rut: '76.123.456-7',
    slug: 'distribuidora-demo',
    plan: 'pro',
    activo: true,
  }).returning('*');

  // Usuario admin
  await db('usuarios').insert({
    tenant_id: tenant.id,
    email: 'admin@demo.cl',
    password_hash: await bcrypt.hash('Demo1234!', 12),
    nombre: 'Admin',
    apellido: 'Demo',
    rol: 'admin',
  });

  // 50 productos con datos realistas del rubro
  const productos = Array.from({ length: 50 }, (_, i) => ({
    tenant_id: tenant.id,
    codigo: `PROD-${String(i + 1).padStart(4, '0')}`,
    nombre: faker.commerce.productName(),
    precio_costo: faker.number.float({ min: 500, max: 5000, fractionDigits: 0 }),
    precio_venta: faker.number.float({ min: 800, max: 8000, fractionDigits: 0 }),
    unidad_medida: ['caja', 'unidad', 'kg', 'litro'][Math.floor(Math.random() * 4)],
    activo: true,
  }));
  await db('productos').insert(productos);

  // 20 clientes
  const clientes = Array.from({ length: 20 }, () => ({
    tenant_id: tenant.id,
    nombre: faker.company.name(),
    rut: `${faker.number.int({ min: 10000000, max: 99999999 })}-${faker.number.int({ min: 0, max: 9 })}`,
    email: faker.internet.email(),
    telefono: faker.phone.number('+56 9 #### ####'),
    ciudad: ['Santiago', 'Valparaíso', 'Concepción', 'Temuco'][Math.floor(Math.random() * 4)],
    limite_credito: faker.number.int({ min: 0, max: 500000 }),
    activo: true,
  }));
  await db('clientes').insert(clientes);

  console.log(`✅ Seed completado: tenant "${tenant.nombre}" creado con datos de prueba`);
}
```

```bash
# Correr seeds en desarrollo
npx knex seed:run

# Resetear BD de desarrollo y volver a sembrar
npx knex migrate:rollback --all && npx knex migrate:latest && npx knex seed:run
```

### Política de actualización de dependencias

```
PARCHES (1.2.3 → 1.2.4):  actualizar inmediatamente si hay fix de seguridad
MINOR   (1.2.x → 1.3.0):  actualizar mensualmente, revisar changelog
MAJOR   (1.x.x → 2.0.0):  evaluar con calma, leer migration guide, testear en rama separada

Proceso para major updates:
  1. Leer el CHANGELOG y breaking changes
  2. Crear rama: upgrade/fastify-v5
  3. Actualizar la dependencia
  4. Correr todos los tests
  5. Hacer deploy a staging y probar manualmente
  6. PR a develop con descripción de los cambios
  7. Merge solo si todos los tests pasan
```

---

## 22. Negocio — Mensajes de Error, Auditoría y Retención

### Mensajes de error para el usuario

Los códigos técnicos internos no deben llegar al usuario. Mapear a mensajes claros en español:

```typescript
// config/mensajes-error.ts
export const MENSAJES_ERROR: Record<string, string> = {
  // Inventario
  STOCK_INSUFICIENTE:     'No hay suficiente stock para completar este pedido.',
  BODEGA_NO_DISPONIBLE:   'La bodega seleccionada no está disponible.',

  // Ventas
  PEDIDO_NO_MODIFICABLE:  'Este pedido ya fue despachado y no puede modificarse.',
  CREDITO_EXCEDIDO:       'El cliente ha superado su límite de crédito disponible.',
  CLIENTE_INACTIVO:       'Este cliente está inactivo. Reactívalo para crear pedidos.',

  // Autenticación
  CREDENCIALES_INVALIDAS: 'Email o contraseña incorrectos.',
  CUENTA_BLOQUEADA:       'Cuenta bloqueada temporalmente por múltiples intentos fallidos. Intenta en 15 minutos.',
  SESION_EXPIRADA:        'Tu sesión ha expirado. Inicia sesión nuevamente.',

  // Plan
  LIMITE_PLAN_ALCANZADO:  'Has alcanzado el límite de tu plan actual. Contáctanos para actualizar.',

  // General
  ERROR_INTERNO:          'Ocurrió un error inesperado. Si persiste, contacta a soporte.',
  SIN_PERMISOS:           'No tienes permisos para realizar esta acción.',
  RECURSO_NO_ENCONTRADO:  'El recurso solicitado no existe o fue eliminado.',
};

// En el error handler global:
const mensajeUsuario = MENSAJES_ERROR[error.codigo] ?? MENSAJES_ERROR.ERROR_INTERNO;
reply.send({ ok: false, error: { codigo: error.codigo, mensaje: mensajeUsuario } });
```

### Auditoría — qué registrar y quién puede verlo

La tabla `audit_log` ya está definida en `BASE_DE_DATOS.md`. Aquí se define qué acciones se registran:

**Acciones que SIEMPRE se auditan:**

| Acción | Tabla | Datos guardados |
|--------|-------|-----------------|
| Crear pedido | pedidos | datos completos del pedido |
| Confirmar pedido | pedidos | estado anterior → nuevo |
| Cancelar pedido | pedidos | estado anterior + motivo |
| Movimiento de inventario | inventario | cantidad, tipo, referencia |
| Cambiar precio de producto | productos | precio anterior → nuevo |
| Crear/editar usuario | usuarios | datos sin password |
| Cambiar rol de usuario | usuarios | rol anterior → nuevo |
| Desactivar cliente/proveedor | clientes/proveedores | razón si se provee |
| Login fallido | — | email, IP, timestamp |
| Ajuste manual de inventario | inventario | cantidad, justificación |

**Quién puede ver el audit log:**

| Rol | Acceso |
|-----|--------|
| `admin` | Todo el audit log del tenant |
| `supervisor` | Acciones de su módulo (ventas ve pedidos, bodeguero ve inventario) |
| `vendedor` | Solo sus propias acciones |
| `bodeguero` | Solo sus propias acciones |
| `chofer` | Solo sus propias acciones |

### Política de retención de datos

Define cuánto tiempo se conserva cada tipo de dato:

| Tipo de dato | Retención | Razón |
|--------------|-----------|-------|
| Pedidos y sus ítems | Permanente | Historial comercial y tributario |
| Movimientos de inventario | Permanente | Trazabilidad completa |
| Órdenes de compra | Permanente | Historial con proveedores |
| Audit log | 5 años | Requisito legal en Chile (SII) |
| Logs de aplicación (Loki) | 90 días | Diagnóstico de problemas |
| Caché Redis | TTL definido por endpoint | Datos temporales |
| Predicciones cache | 7 días | Se regeneran periódicamente |
| Intentos fallidos de login | 24 horas | Solo para brute force |
| Tokens JWT revocados | Hasta expiración natural | Máximo 7 días |
| Datos de tenants inactivos | 1 año después de baja | Posible reactivación |

> **Nota legal:** en Chile, el SII puede solicitar información tributaria de los últimos 6 años. Los documentos relacionados con ventas y compras deben conservarse al menos ese tiempo.