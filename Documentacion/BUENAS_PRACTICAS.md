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
- SQL Injection: usar siempre queries parametrizadas — **nunca** string concatenation en SQL

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
