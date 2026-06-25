# ARQUITECTURA.md — Stack Tecnológico y Justificaciones

---

## 1. Frontend Web — React

### Decisión: React + Vite + TypeScript

**¿Por qué React?**
- Ecosistema maduro con librerías especializadas para dashboards (Recharts, TanStack Table)
- Ecosistema maduro con librerías especializadas para dashboards y tablas de datos
- Amplia disponibilidad de desarrolladores si el equipo crece
- Mejor soporte para aplicaciones de datos complejas vs Vue o Svelte

**¿Por qué Vite y no Create React App?**
- CRA está oficialmente deprecado
- Vite ofrece HMR casi instantáneo y builds optimizados
- Soporte nativo de TypeScript sin configuración extra

**Alternativas evaluadas:**

| Opción | Por qué se descartó |
|--------|---------------------|
| Next.js | SSR innecesario para un ERP (app autenticada, no SEO) · Complejidad extra sin beneficio |
| Vue 3 | Ecosistema más pequeño para dashboards complejos · Menos librerías de datos |
| Angular | Curva de aprendizaje alta · Menos flexible para dashboards custom |

**Stack Web Completo:**
```
React 18 + TypeScript
Vite (bundler)
TanStack Router (routing type-safe)
TanStack Query (server state / caché)
Zustand (estado global ligero)
Tailwind CSS + shadcn/ui (componentes)
Recharts (gráficos)
TanStack Table (tablas con filtros/paginación)
React Hook Form + Zod (formularios con validación)
```

---

## 2. App Móvil Android — Flutter

### Decisión: Flutter + Dart (solo Android)

La app móvil está dirigida exclusivamente a Android, orientada a operaciones de campo (bodegueros, repartidores, choferes). Dado que no hay requerimiento de iOS, el argumento principal para React Native (un codebase, dos plataformas) desaparece.

**¿Por qué Flutter y no Kotlin nativo?**

Flutter compila a código nativo ARM igual que Kotlin — no hay bridge de JavaScript como en React Native, por lo que el rendimiento es prácticamente idéntico al nativo. La diferencia es que Flutter tiene su propio motor de renderizado (Impeller) que dibuja cada píxel directamente, lo que garantiza consistencia visual en cualquier dispositivo Android sin importar la capa del fabricante (Samsung, Motorola, Xiaomi).

Para el tipo de operaciones que cubre esta app (listas de inventario, formularios de entrega, firma digital, notificaciones), Flutter es indistinguible de Kotlin nativo en rendimiento, y ofrece una ventaja real: si en el futuro se decide agregar iOS, no se reescribe nada.

**¿Por qué no Kotlin nativo entonces?**
Kotlin es la opción óptima si Android es 100% definitivo para siempre y se quiere el máximo control sobre APIs del sistema. Para este proyecto, Flutter da el mismo rendimiento con la puerta de iOS abierta, lo que lo hace la mejor apuesta a mediano plazo.

**¿Qué funciones estarán en mobile?**
El móvil no replica la web. Se enfoca en operaciones de campo:
- Consulta y movimiento de inventario (bodeguero)
- Registro de entregas y firma digital del receptor (repartidor)
- Ver pedidos y rutas asignadas (chofer)
- Notificaciones push de alertas críticas (stock bajo, nuevo pedido asignado)
- Modo offline básico (ver últimos datos descargados sin conexión)

**Alternativas evaluadas:**

| Opción | Por qué se descartó |
|--------|---------------------|
| React Native | Bridge JavaScript · Rendimiento inferior en gama baja · Sin ventaja real si es solo Android |
| Kotlin nativo | Cierra la puerta a iOS futuro · Misma complejidad sin beneficio extra sobre Flutter |
| PWA | Sin acceso a cámara nativa confiable · Push notifications limitadas en Android sin Play Services |
| Ionic | Rendimiento notoriamente inferior en listas largas de inventario |

**Stack Flutter:**
```
Flutter (Dart)
Riverpod (manejo de estado)
Dio (cliente HTTP)
Hive (almacenamiento offline local)
flutter_local_notifications (notificaciones push)
signature (firma digital en pantalla táctil)
mobile_scanner (escaneo de códigos de barra/QR)
```

---

## 3. Backend — Node.js + Fastify (Core) + Python (Analytics)

### Por qué dos lenguajes de backend

La separación **Node.js / Python** no es arbitraria: cada uno resuelve lo que hace mejor.

```
┌─────────────────────────────────────────────────────────┐
│  Node.js + Fastify                                       │
│  · API REST/GraphQL principal                            │
│  · CRUD de todos los módulos                             │
│  · Autenticación y autorización                          │
│  · Notificaciones en tiempo real (WebSockets)            │
│  · Jobs de bajo costo (emails, alertas)                  │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│  Python + FastAPI                                        │
│  · Motor de analytics y KPIs                             │
│  · Modelos de predicción (Prophet, scikit-learn)         │
│  · Simulaciones de temporada / escenarios                │
│  · Procesamiento batch de reportes pesados               │
└─────────────────────────────────────────────────────────┘
```

**¿Por qué Fastify y no Express?**
- 2–3x más rápido que Express en benchmarks reales
- Validación de esquemas JSON integrada (mismo efecto que Zod pero en la capa HTTP)
- Soporte TypeScript nativo
- Plugin ecosystem bien mantenido

**¿Por qué FastAPI para Python y no Flask/Django?**
- Tipado nativo con Pydantic (consistente con TypeScript en Node)
- Performance comparable a Node.js gracias a async/await nativo
- Documentación automática (Swagger/OpenAPI) — útil para debugging
- Django es demasiado opinionado para un servicio especializado en analytics

**Comunicación entre servicios:**
```
API Node.js ──HTTP interno──► Python FastAPI
                           (llamadas síncronas para reportes)
API Node.js ──Redis Queue──► Python Worker
                           (jobs async: predicciones, reportes pesados)
```

---

## 4. Base de Datos — PostgreSQL

### Decisión: PostgreSQL 16

**¿Por qué PostgreSQL y no MySQL?**

| Característica | PostgreSQL | MySQL |
|----------------|-----------|-------|
| Row Level Security (RLS) | ✅ Nativo y robusto | ❌ No existe |
| JSON/JSONB avanzado | ✅ Operadores ricos | ⚠️ Básico |
| Window functions | ✅ Completo | ⚠️ Limitado |
| Full-text search | ✅ Integrado | ⚠️ Limitado |
| Particionamiento de tablas | ✅ Nativo | ⚠️ Básico |
| Extensiones (TimescaleDB, PostGIS) | ✅ | ❌ |

> **RLS es el motivo principal.** Para multitenancy, PostgreSQL permite que cada fila de datos solo sea visible para el tenant correcto, **a nivel de base de datos**, no solo en código. Esto es seguridad en profundidad.

**Extensiones a usar:**
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- UUIDs como PKs
CREATE EXTENSION IF NOT EXISTS "pg_trgm";      -- Búsqueda de texto difuso
CREATE EXTENSION IF NOT EXISTS "btree_gin";    -- Índices compuestos eficientes
```

**¿Se podría agregar TimescaleDB en el futuro?**
Sí. Para series de tiempo (métricas de ventas por hora, tracking de inventario), TimescaleDB como extensión de PostgreSQL es ideal. No requiere migrar de base de datos.

---

## 5. Caché y Jobs — Redis

### Roles de Redis en el sistema

```
1. CACHÉ DE SESIONES
   JWT blacklist · Sesiones activas · Tokens de refresh

2. CACHÉ DE CONSULTAS
   Resultados de reportes costosos (5-15 min TTL)
   Datos de catálogo (productos, proveedores)

3. COLA DE TRABAJOS (con BullMQ)
   Generación de reportes PDF
   Envío de emails/notificaciones
   Jobs de predicción ML en Python
   Sincronización futura con SII

4. RATE LIMITING
   Límites por tenant por hora/minuto
```

**¿Por qué BullMQ y no cron jobs simples?**
- Reintentos automáticos con backoff exponencial
- Visibilidad del estado de cada job (UI con Bull Board)
- Prioridades: un reporte urgente puede saltar la cola
- Concurrencia configurable por tipo de job

---

## 6. Infraestructura — Servidor Propio

### Setup recomendado

```
SERVIDOR PRINCIPAL (VPS o bare metal propio)
├── Docker + Docker Compose (orquestación local)
├── Nginx (reverse proxy + SSL termination)
├── Certbot (certificados SSL automáticos)
└── Contenedores:
    ├── api-node (Node.js Fastify)
    ├── api-python (FastAPI)
    ├── worker-python (BullMQ consumer)
    ├── postgresql
    ├── redis
    └── monitoring (Prometheus + Grafana)

BACKUPS
├── pg_dump diario → almacenamiento externo (Backblaze B2 / S3)
└── Retención: 30 días diarios + 12 meses mensuales
```

**¿Por qué Docker y no instalar directo en el servidor?**
- Entornos reproducibles: dev = staging = producción
- Actualizaciones sin downtime (rolling deploy)
- Rollback inmediato si algo falla
- Fácil migración a otro servidor si es necesario

**¿Por qué Nginx y no el servidor HTTP de Node?**
- Nginx maneja SSL, compresión y static files mucho más eficientemente
- Protección contra slowloris y otros ataques HTTP básicos
- Balanceo de carga si en el futuro se escala horizontalmente

### Especificaciones de servidor recomendadas

| Fase | vCPU | RAM | Almacenamiento | Costo estimado VPS |
|------|------|-----|----------------|-------------------|
| Fase 1 (lanzamiento) | 8 | 32 GB | 500 GB SSD NVMe | ~$80–120 USD/mes |
| Fase 2 (año 1) | 16 | 64 GB | 1 TB SSD NVMe | ~$180–250 USD/mes |

> **Recomendación de proveedores:** Hetzner (mejor precio/performance), DigitalOcean, o un servidor físico propio si tienes datacenter disponible.

---

## 7. Monitoreo

```
Prometheus    → recolecta métricas del servidor y servicios
Grafana       → dashboards de métricas (CPU, RAM, queries lentas)
Loki          → agregación de logs de todos los contenedores
Alertmanager  → alertas por email/Telegram cuando algo falla
Sentry        → errores de aplicación en tiempo real (Node + React)
```

---

## Diagrama de Componentes Completo

```
Internet
    │
    ▼
[Cloudflare DNS + DDoS Protection] (opcional pero recomendado)
    │
    ▼
[Nginx Reverse Proxy · SSL · Rate Limit]
    │
    ├──────────────────────┐
    ▼                      ▼
[Node.js API]         [Static Files React]
    │
    ├──► [PostgreSQL + RLS]
    ├──► [Redis Cache/Queue]
    └──► [Python FastAPI / Workers]
              │
              └──► [Modelos ML / Pandas / Prophet]
```

---

*Ver [BASE_DE_DATOS.md](./BASE_DE_DATOS.md) para el esquema detallado de PostgreSQL y estrategia RLS.*
