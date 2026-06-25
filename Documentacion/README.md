# Thoth — Documentación de Arquitectura

> Sistema ERP para distribuidoras · Multitenancy · SaaS On-Premise · Chile

---

## Índice de Documentos

| # | Documento | Descripción |
|---|-----------|-------------|
| 1 | [README.md](./README.md) | Este archivo — visión general y decisiones macro |
| 2 | [ARQUITECTURA.md](./ARQUITECTURA.md) | Stack tecnológico, justificaciones y alternativas |
| 3 | [BASE_DE_DATOS.md](./BASE_DE_DATOS.md) | Esquema PostgreSQL, RLS, multitenancy |
| 4 | [MODULOS.md](./MODULOS.md) | Especificación de cada módulo funcional |
| 5 | [API.md](./API.md) | Diseño de la API REST/GraphQL y autenticación |
| 6 | [ANALYTICS.md](./ANALYTICS.md) | Dashboards, KPIs, predicciones y simulaciones |
| 7 | [ROADMAP.md](./ROADMAP.md) | Fases de desarrollo y prioridades |
| 8 | [BUENAS_PRACTICAS.md](./BUENAS_PRACTICAS.md) | Seguridad, CI/CD, testing, convenciones |

---

## Visión del Producto

**Thoth** es un sistema ERP SaaS multitenant orientado principalmente a distribuidoras (pequeñas, medianas y grandes), con capacidad de expansión a otros rubros. Opera sobre un servidor central propio, con interfaz web (React) y aplicación móvil Android (Flutter).

### Propuesta de valor

- Gestión completa del ciclo operativo: compras → bodega → inventario → ventas → reparto
- Control de flota y empleados integrado al flujo logístico
- Analytics predictivo con datos históricos propios del negocio
- Integración futura con SII Chile (boletas electrónicas)
- Arquitectura multitenancy: un servidor, múltiples empresas cliente

---

## Decisiones Macro

### ¿Por qué SaaS propio y no soluciones existentes (SAP, Bsale, etc.)?

| Factor | Soluciones existentes | Thoth |
|--------|-----------------------|-------------|
| Control total del código | ❌ | ✅ |
| Personalización profunda | ❌ Limitada | ✅ Total |
| Costo a escala | ❌ Crece por usuario | ✅ Costo fijo servidor |
| Integración SII personalizada | ❌ Genérica | ✅ A medida |
| Modelo de negocio propio | ❌ | ✅ |

### ¿Por qué multitenancy centralizado y no on-premise por cliente?

Dado que el objetivo es un negocio SaaS con múltiples clientes (distribuidoras), el modelo **multitenancy en servidor propio** es la opción correcta porque:

- Un solo punto de despliegue y actualización
- Los clientes no necesitan infraestructura propia
- Escalamiento vertical/horizontal controlado por ti
- Seguridad centralizada con RLS a nivel de base de datos

> **Alternativa descartada:** On-premise por cliente. Viable solo si el cliente exige soberanía total de datos por razones legales o de tamaño. Se puede ofrecer como tier premium en el futuro.

---

## Stack Resumen

```
┌─────────────────────────────────────────────┐
│              CLIENTES                        │
│   React (Web)    │    Flutter (Móvil Android)│
└──────────────────┴──────────────────────────┘
                   │
             HTTPS / WSS
                   │
┌─────────────────────────────────────────────┐
│              API GATEWAY                     │
│         Node.js + Fastify                    │
│   Autenticación JWT · Rate Limiting · CORS   │
└─────────────────────────────────────────────┘
          │               │
   REST/GraphQL       WebSockets
          │               │
┌─────────┴───────────────┴───────────────────┐
│           SERVICIOS BACKEND                  │
│  Node.js (core)  │  Python (analytics/ML)   │
└──────────────────┴──────────────────────────┘
                   │
┌─────────────────────────────────────────────┐
│           BASE DE DATOS                      │
│         PostgreSQL + RLS                     │
│    Redis (caché/sesiones/jobs)               │
└─────────────────────────────────────────────┘
```

---

## Módulos del Sistema

```
Thoth
├── 📦 Gestión de Inventario
│   ├── Stock por bodega
│   ├── Movimientos (entrada/salida/transferencia)
│   └── Alertas de mínimos
├── 🏪 Gestión de Bodegas
│   ├── Ubicaciones y sectores
│   └── Control de acceso por empleado
├── 💰 Gestión de Ventas
│   ├── Pedidos y facturación
│   ├── Clientes y crédito
│   └── (Futuro) Integración SII
├── 🛒 Gestión de Compras
│   ├── Proveedores y órdenes de compra
│   └── Recepción y conciliación
├── 👥 Gestión de Empleados
│   ├── Roles y permisos
│   └── Asignación a rutas/bodegas
├── 🚛 Gestión de Flota
│   ├── Vehículos y mantenimiento
│   └── Rutas y asignación de conductores
└── 📊 Analytics & BI
    ├── Dashboards KPI
    ├── Reportes operacionales
    └── Predicciones y simulaciones
```

---

## Escala Objetivo

| Métrica | Fase 1 (lanzamiento) | Fase 2 (año 1) |
|---------|----------------------|-----------------|
| Usuarios simultáneos | 40–50 | 100–200 |
| Tenants (empresas) | 1–5 | 10–30 |
| Registros en BD | < 5M | < 50M |
| Servidor recomendado | 8 vCPU / 32 GB RAM | 16 vCPU / 64 GB RAM |

---

*Última actualización: Junio 2026 · Versión de arquitectura: 1.0*
