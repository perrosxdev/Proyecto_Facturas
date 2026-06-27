# Thoth — Documentación de Arquitectura

> Sistema ERP para distribuidoras · Multitenancy · SaaS On-Premise · Chile

---

## Índice de Documentos

| # | Documento | Descripción |
|---|-----------|-------------|
| 0 | [INICIO.md](./Documentacion/INICIO.md) | **Empieza aquí** — guía paso a paso de todo el proyecto |
| 1 | [ARQUITECTURA.md](./Documentacion/ARQUITECTURA.md) | Stack tecnológico, justificaciones y alternativas |
| 2 | [BASE_DE_DATOS.md](./Documentacion/BASE_DE_DATOS.md) | Esquema PostgreSQL, RLS, multitenancy |
| 3 | [MODULOS.md](./Documentacion/MODULOS.md) | Especificación de cada módulo funcional |
| 4 | [API.md](./Documentacion/API.md) | Diseño de la API REST/GraphQL y autenticación |
| 5 | [ANALYTICS.md](./Documentacion/ANALYTICS.md) | Dashboards, KPIs, predicciones y simulaciones |
| 6 | [ROADMAP.md](./Documentacion/ROADMAP.md) | Fases de desarrollo y prioridades |
| 7 | [BUENAS_PRACTICAS.md](./Documentacion/BUENAS_PRACTICAS.md) | Seguridad, CI/CD, testing, convenciones |
| 8 | [Servidor.md](./Servidor_Documentacion/Servidor.md) | Hardware, instalación y administración del servidor |

---

## ¿Qué es Thoth?

**Thoth** es un sistema ERP SaaS multitenant orientado principalmente a distribuidoras (pequeñas, medianas y grandes), con capacidad de expansión a otros rubros en el futuro. Opera sobre un servidor central propio, con interfaz web (React) y aplicación móvil Android (Flutter).

### Origen del proyecto

Thoth nace de una necesidad concreta: la distribuidora de huevos familiar necesitaba una forma de gestionar facturas, inventario y operaciones sin depender de soluciones genéricas o costosas. Durante el proceso de investigación quedó claro que el problema era más amplio — emitir documentos tributarios requiere cumplir con los requisitos del SII y tener la empresa formalmente constituida, y gestionar solo facturas sin el resto de los procesos no resuelve el problema real.

De ahí nació la decisión de construir un sistema integral que cubra todos los procesos operativos de una distribuidora en una sola plataforma.

### Principio de diseño

> La aplicación debe ser completamente intuitiva. Cualquier persona, incluso sin experiencia tecnológica, debe poder usarla sin dificultad.

Este principio guía todas las decisiones de UX y flujo de la aplicación — si algo requiere capacitación extensa, está mal diseñado.

---

## ¿Qué Problemas Resuelve?

| Problema real | Cómo lo resuelve Thoth |
|---------------|------------------------|
| Gestionar inventario en múltiples bodegas | Stock independiente por bodega con visión consolidada |
| Controlar quién ve qué información | Permisos por bodega — cada usuario solo accede a sus datos |
| Coordinar entregas entre bodegas y clientes | Módulo de flota integrado al flujo de pedidos |
| Emitir documentos tributarios (futuro) | Integración SII — boletas y facturas electrónicas |
| Tomar decisiones con datos reales | Analytics con KPIs, dashboards y predicciones |
| Operar desde cualquier lugar | Web + app Android accesibles desde cualquier dispositivo |

---

## Funcionalidades Principales

```
Thoth
├── 👥 Gestión de Empleados
│   ├── Agregar, editar y desactivar personal
│   ├── Roles y permisos por módulo
│   └── Asignación a bodegas específicas
├── 🏪 Gestión de Bodegas y Locales
│   ├── Múltiples puntos de almacenamiento y distribución
│   ├── Control de acceso por bodega (usuarios ven solo sus datos)
│   └── Transferencias de inventario entre bodegas
├── 📦 Gestión de Inventario
│   ├── Stock independiente por bodega
│   ├── Movimientos (entrada, salida, transferencia, ajuste)
│   └── Alertas automáticas de stock mínimo
├── 🗂️ Gestión de Productos
│   └── Catálogo centralizado de artículos
├── 🤝 Gestión de Proveedores
│   └── Registro de proveedores y productos asociados
├── 💰 Gestión de Ventas
│   ├── Pedidos y seguimiento por bodega
│   ├── Gestión de clientes y crédito
│   └── (Futuro) Integración SII — boletas y facturas electrónicas
├── 🛒 Gestión de Compras
│   ├── Órdenes de compra a proveedores
│   └── Recepción y actualización automática de inventario
├── 🚛 Gestión de Flota
│   ├── Vehículos y registro de mantenimientos
│   └── Rutas y asignación de conductores a pedidos
└── 📊 Analytics & BI
    ├── Dashboards interactivos con KPIs en tiempo real
    ├── Reportes exportables (Excel / PDF)
    └── Predicciones de demanda y simulaciones de temporada
```

---

## Arquitectura Multi-Bodega

Un aspecto clave del sistema es la capacidad de gestionar múltiples bodegas de forma independiente pero integrada. Cada bodega tiene:

- Inventario propio con visión consolidada desde la administración central
- Usuarios asignados con permisos limitados a su bodega — solo ven y modifican datos de su ubicación
- Transacciones independientes (ventas, compras, movimientos) registradas por bodega
- Reportes y estadísticas específicas por bodega y consolidadas
- Transferencias de inventario entre bodegas con trazabilidad completa

> Es un sistema de **permisos de acceso a datos**, no un requisito de presencia física. Los datos se registran en la bodega asignada del usuario, sin importar desde dónde se ingrese la información.

Esto permite que distribuidoras con múltiples puntos de venta mantengan control total sobre cada ubicación mientras conservan una visión consolidada del negocio.

---

## Decisiones Macro

### ¿Por qué construir Thoth y no usar soluciones existentes (SAP, Bsale, etc.)?

| Factor | Soluciones existentes | Thoth |
|--------|-----------------------|-------|
| Control total del código | ❌ | ✅ |
| Personalización profunda | ❌ Limitada | ✅ Total |
| Costo a escala | ❌ Crece por usuario | ✅ Costo fijo servidor |
| Integración SII personalizada | ❌ Genérica | ✅ A medida |
| Adaptado al rubro distribución Chile | ❌ | ✅ |
| Modelo de negocio propio (SaaS) | ❌ | ✅ |

### ¿Por qué multitenancy centralizado y no un sistema por empresa?

El objetivo a largo plazo es que Thoth sea un negocio SaaS — múltiples distribuidoras usando la misma plataforma. El modelo **multitenancy en servidor propio** es el correcto porque:

- Un solo punto de despliegue y actualización para todos los clientes
- Los clientes no necesitan infraestructura propia
- Seguridad centralizada con RLS (Row Level Security) a nivel de base de datos
- Escalamiento controlado

> La seguridad entre empresas se garantiza a nivel de base de datos con PostgreSQL RLS — aunque hubiera un bug en el código, la BD nunca devuelve datos de otra empresa.

---

## Stack Resumen

```
┌──────────────────────────────────────────────┐
│                  CLIENTES                    │
│   React (Web)    │   Flutter (Móvil Android) │
└──────────────────┴───────────────────────────┘
                   │
             HTTPS / WSS
                   │
┌──────────────────────────────────────────────┐
│               API GATEWAY                    │
│          Node.js + Fastify                   │
│   Autenticación JWT · Rate Limiting · CORS   │
└──────────────────────────────────────────────┘
          │                │
   REST/GraphQL        WebSockets
          │                │
┌─────────┴────────────────┴───────────────────┐
│            SERVICIOS BACKEND                 │
│  Node.js (core)   │  Python (analytics/ML)  │
└───────────────────┴──────────────────────────┘
                   │
┌──────────────────────────────────────────────┐
│              BASE DE DATOS                   │
│           PostgreSQL + RLS                   │
│      Redis (caché / sesiones / jobs)         │
└──────────────────────────────────────────────┘
```

---

## Escala Objetivo

| Métrica | Fase 1 (lanzamiento) | Fase 2 (año 1) |
|---------|----------------------|----------------|
| Usuarios simultáneos | 40–50 | 100–200 |
| Empresas cliente (tenants) | 1–5 | 10–30 |
| Registros en BD | < 5M | < 50M |
| Hardware recomendado | Ryzen 7 8700G / 32 GB RAM | Ryzen 9 9900X / 96 GB RAM |

---

*Proyecto Thoth · Documentación v1.0 · Junio 2026*