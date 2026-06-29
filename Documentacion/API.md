# API.md — Diseño de la API, Autenticación y Endpoints

---

## 1. Arquitectura de la API

### REST vs GraphQL — Decisión híbrida

| Uso | Protocolo | Razón |
|-----|-----------|-------|
| CRUD estándar (pedidos, productos, etc.) | **REST** | Simple, cacheável, fácil de versionar |
| Dashboards y reportes (muchos datos relacionados) | **GraphQL** | Evita over-fetching, un solo request para datos complejos |
| Notificaciones en tiempo real | **WebSockets** | Stock bajo, estado de pedido, alertas |

> La combinación REST + GraphQL no es inconsistencia — es pragmatismo. GraphQL brilla en consultas complejas para dashboards; REST es más claro para operaciones CRUD.

---

## 2. Autenticación — JWT con Refresh Tokens

```
1. POST /auth/login
   → Valida email + password
   → Genera Access Token (15 min) + Refresh Token (7 días)
   → Refresh Token se guarda en Redis con tenant_id + user_id

2. Cada request con Access Token
   → API verifica firma JWT
   → Extrae tenant_id y user_id del payload
   → SET app.current_tenant = tenant_id en PostgreSQL

3. POST /auth/refresh
   → Verifica Refresh Token en Redis
   → Emite nuevo Access Token
   → Rota el Refresh Token (cada uso genera uno nuevo)

4. POST /auth/logout
   → Agrega Access Token a blacklist en Redis (hasta que expire)
   → Elimina Refresh Token de Redis
```

### Estructura del JWT

```json
{
  "sub": "uuid-usuario",
  "tenant": "uuid-tenant",
  "rol": "admin",
  "email": "usuario@empresa.com",
  "iat": 1718000000,
  "exp": 1718000900
}
```

### Roles y permisos

```typescript
const PERMISOS = {
  admin: ['*'],  // todo
  supervisor: [
    'ventas:read', 'ventas:write',
    'inventario:read', 'inventario:write',
    'compras:read', 'compras:write',
    'empleados:read', 'flota:read',
    'reportes:read'
  ],
  vendedor: ['ventas:read', 'ventas:write', 'inventario:read', 'clientes:read', 'clientes:write'],
  bodeguero: ['inventario:read', 'inventario:write', 'compras:read'],
  chofer: ['rutas:read', 'rutas:write'],  // solo sus rutas asignadas
};
```

---

## 3. Estructura de URLs

```
BASE_URL: https://api.thoth.cl/v1

/auth
  POST   /auth/login
  POST   /auth/refresh
  POST   /auth/logout
  GET    /auth/me

/inventario
  GET    /inventario                     → stock por bodega
  GET    /inventario/alertas             → productos bajo mínimo
  POST   /inventario/movimiento          → registrar movimiento
  GET    /inventario/movimientos         → historial con filtros

/productos
  GET    /productos
  POST   /productos
  GET    /productos/:id
  PUT    /productos/:id
  DELETE /productos/:id (soft delete: activo=false)

/bodegas
  GET    /bodegas
  POST   /bodegas
  GET    /bodegas/:id/stock

/pedidos
  GET    /pedidos                        → con filtros: estado, fecha, cliente
  POST   /pedidos
  GET    /pedidos/:id
  PUT    /pedidos/:id
  POST   /pedidos/:id/confirmar
  POST   /pedidos/:id/cancelar
  GET    /pedidos/:id/items

/clientes
  GET    /clientes
  POST   /clientes
  GET    /clientes/:id
  PUT    /clientes/:id
  GET    /clientes/:id/pedidos
  GET    /clientes/:id/saldo

/compras
  GET    /compras/ordenes
  POST   /compras/ordenes
  GET    /compras/ordenes/:id
  POST   /compras/ordenes/:id/recibir    → recepción parcial o total
  GET    /compras/proveedores
  POST   /compras/proveedores

/flota
  GET    /flota/vehiculos
  POST   /flota/vehiculos
  GET    /flota/rutas
  POST   /flota/rutas
  PUT    /flota/rutas/:id/estado        → actualizar estado desde móvil

/empleados
  GET    /empleados
  POST   /empleados
  GET    /empleados/:id
  PUT    /empleados/:id

/reportes (GraphQL endpoint)
  POST   /graphql                        → queries de dashboard y analytics
```

---

## 4. Formato de Respuestas

### Éxito

```json
{
  "ok": true,
  "data": { ... },
  "meta": {
    "total": 150,
    "pagina": 1,
    "por_pagina": 25
  }
}
```

### Error

```json
{
  "ok": false,
  "error": {
    "codigo": "STOCK_INSUFICIENTE",
    "mensaje": "Stock insuficiente para producto 'Huevos blancos L'. Disponible: 10, solicitado: 50.",
    "detalles": {
      "producto_id": "uuid",
      "stock_disponible": 10,
      "cantidad_solicitada": 50
    }
  }
}
```

### Códigos de error del negocio (ejemplos)

| Código | Situación |
|--------|-----------|
| `STOCK_INSUFICIENTE` | No hay stock para el movimiento |
| `CREDITO_EXCEDIDO` | El cliente supera su límite de crédito |
| `VEHICULO_NO_DISPONIBLE` | Vehículo en mantenimiento |
| `PEDIDO_NO_MODIFICABLE` | El pedido ya está en reparto |
| `RUT_DUPLICADO` | RUT ya registrado para este tenant |
| `TENANT_SUSPENDIDO` | El plan del tenant está vencido |

---

## 5. Paginación y Filtros

```
GET /pedidos?pagina=1&por_pagina=25&estado=confirmado&desde=2026-01-01&hasta=2026-06-30&cliente_id=uuid

Parámetros estándar:
  pagina        → número de página (default: 1)
  por_pagina    → registros por página (default: 25, max: 100)
  orden         → campo de ordenamiento (ej: fecha_pedido)
  direccion     → asc | desc (default: desc)
  buscar        → búsqueda de texto (usa pg_trgm)
```

---

## 6. WebSockets — Notificaciones en Tiempo Real

```
WS_URL: wss://api.thoth.cl/ws

Autenticación: el cliente envía el JWT en el primer mensaje:
  { "tipo": "auth", "token": "eyJ..." }

Eventos que el servidor emite al cliente:

  { "evento": "stock_bajo",
    "data": { "producto_id": "...", "nombre": "...", "stock": 5, "minimo": 10 } }

  { "evento": "pedido_actualizado",
    "data": { "pedido_id": "...", "estado_nuevo": "en_reparto" } }

  { "evento": "entrega_completada",
    "data": { "ruta_id": "...", "pedido_id": "..." } }

  { "evento": "vehiculo_alerta",
    "data": { "vehiculo_id": "...", "tipo": "mantenimiento_proximo" } }
```

---

## 7. Rate Limiting

```
Por tenant (no por usuario individual):

  Endpoints normales:    300 requests / minuto
  Reportes y analytics: 20 requests / minuto (son costosos)
  Auth:                  10 intentos / 15 minutos (protección brute force)

Implementado con Redis (clave: "rl:tenant_id:endpoint_group:ventana")
```

---

## 8. Idempotencia

Previene operaciones duplicadas cuando el usuario hace doble clic, la red falla y reintenta, o el cliente envía la misma request más de una vez.

### Cómo funciona

El cliente genera un UUID único por cada **intención de operación** y lo envía en el header `Idempotency-Key`. Si el servidor recibe la misma key dos veces, devuelve el resultado de la primera sin reprocesar nada.

```
1. Usuario hace clic en "Confirmar pedido"
   → cliente genera: Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000

2. Primera request llega al servidor
   → no existe en Redis → procesar → guardar resultado en Redis → responder

3. Usuario hace doble clic (segunda request con la misma key)
   → existe en Redis → devolver resultado guardado → no se crea pedido duplicado
```

### Implementación en Fastify

```typescript
// middleware/idempotency.ts
import { FastifyRequest, FastifyReply } from 'fastify';
import { redis } from '../plugins/redis';

const IDEMPOTENCY_TTL = 86400; // 24 horas en segundos

export async function idempotencyMiddleware(req: FastifyRequest, reply: FastifyReply) {
  const key = req.headers['idempotency-key'] as string;
  if (!key) return; // si el cliente no manda key, procesar normalmente

  const redisKey = `idempotency:${req.user.tenantId}:${key}`;

  // Verificar si ya existe un resultado para esta key
  const cached = await redis.get(redisKey);
  if (cached) {
    const { statusCode, body } = JSON.parse(cached);
    return reply.code(statusCode).send(body);
  }

  // Marcar como "en proceso" para evitar race conditions
  const locked = await redis.set(redisKey, JSON.stringify({ status: 'processing' }), {
    EX: IDEMPOTENCY_TTL,
    NX: true, // solo setear si NO existe
  });

  if (!locked) {
    return reply.code(409).send({
      ok: false,
      error: { codigo: 'REQUEST_EN_PROCESO', mensaje: 'Esta operación ya está siendo procesada.' }
    });
  }

  // Guardar el resultado real al enviar la respuesta
  reply.addHook('onSend', async (_req, _reply, payload) => {
    await redis.set(redisKey, JSON.stringify({
      statusCode: reply.statusCode,
      body: payload,
    }), { EX: IDEMPOTENCY_TTL });
  });
}
```

### Registro en Fastify

```typescript
// Aplicar solo a rutas POST que crean recursos
fastify.addHook('preHandler', async (req, reply) => {
  if (req.method === 'POST') {
    await idempotencyMiddleware(req, reply);
  }
});
```

### Cómo lo llama el cliente (React / Flutter)

```typescript
// utils/api.ts — generar key una sola vez por acción del usuario
import { v4 as uuidv4 } from 'uuid';

async function confirmarPedido(pedidoData: NuevoPedido) {
  const idempotencyKey = uuidv4(); // se genera antes de enviar, no en cada reintento

  return fetch('/api/v1/pedidos', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
      'Idempotency-Key': idempotencyKey, // misma key en reintentos
    },
    body: JSON.stringify(pedidoData),
  });
}
```

> **Importante:** el cliente debe generar la key **antes** de intentar la operación
> y reutilizar la misma key si reintenta por error de red.
> Generar una key nueva en cada reintento elimina completamente la protección.

### Endpoints donde es obligatorio

| Endpoint | Riesgo sin idempotencia |
|----------|------------------------|
| `POST /pedidos` | Pedido duplicado — cliente cobrado dos veces |
| `POST /pedidos/:id/confirmar` | Stock descontado dos veces |
| `POST /inventario/movimiento` | Movimiento de inventario duplicado |
| `POST /compras/ordenes` | Orden de compra duplicada al proveedor |
| `POST /compras/ordenes/:id/recibir` | Mercadería ingresada dos veces al stock |
| `POST /flota/rutas` | Ruta duplicada asignada al mismo conductor |

### Endpoints donde NO aplica

| Endpoint | Razón |
|----------|-------|
| `GET *` | Las lecturas son naturalmente idempotentes |
| `PUT *` | Actualizar con los mismos datos dos veces da el mismo resultado |
| `DELETE *` | Eliminar algo inexistente devuelve 404 — aceptable |
| `POST /auth/login` | No crea recursos — sin riesgo de duplicado |

---

## 9. Versionamiento

La API se versiona en la URL (`/v1/`, `/v2/`).

- Una versión mayor solo se depreca con **6 meses de aviso** previo
- La versión antigua sigue funcionando durante el período de deprecación
- Se notifica a los tenants por email con changelog y guía de migración
- Nunca se hacen breaking changes dentro de la misma versión mayor

---

*Ver [ANALYTICS.md](./ANALYTICS.md) para el diseño del módulo de reportes y predicciones.*