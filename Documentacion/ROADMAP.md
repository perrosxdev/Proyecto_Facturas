# ROADMAP.md — Fases de Desarrollo

> Principio rector: **nunca construir lo que no se puede probar**. Cada fase debe terminar con algo funcionando end-to-end.

---

## Visión General

```
FASE 0 · Setup         [2–3 semanas]  · Infraestructura y fundaciones
FASE 1 · Core          [6–8 semanas]  · Inventario + Ventas básico
FASE 2 · Operaciones   [6–8 semanas]  · Compras + Flota + Empleados
FASE 3 · Analytics     [4–6 semanas]  · Dashboards + KPIs + Predicciones
FASE 4 · Mobile        [6–8 semanas]  · App Android (Flutter)
FASE 5 · SII           [4–6 semanas]  · Integración boletas electrónicas
FASE 6 · Scale         [ongoing]      · Performance, multi-rubro, marketplace
```

---

## FASE 0 — Setup e Infraestructura

**Objetivo:** Tener el esqueleto técnico funcionando antes de escribir una sola línea de negocio.

### Tareas

- [ ] Configurar servidor (VPS o físico)
- [ ] Instalar Docker + Docker Compose
- [ ] Configurar Nginx + SSL con Certbot
- [ ] Inicializar repositorio Git con monorepo structure:
  ```
  thoth/
  ├── apps/
  │   ├── web/          → React
  │   ├── mobile/       → Flutter (Android)
  │   ├── api-node/     → Fastify
  │   └── api-python/   → FastAPI
  ├── packages/
  │   ├── shared-types/ → TypeScript types compartidos
  │   └── shared-utils/ → Funciones compartidas (formateo, validaciones)
  ├── db/
  │   ├── migrations/   → SQL con numeración: 001_init.sql
  │   └── seeds/        → Datos de prueba
  └── docker-compose.yml
  ```
- [ ] Configurar PostgreSQL con usuario `app_user` (sin superuser)
- [ ] Ejecutar migraciones base (tenants, usuarios, RLS)
- [ ] Configurar Redis
- [ ] Setup monitoreo básico (Prometheus + Grafana)
- [ ] Configurar Sentry para errores
- [ ] Pipeline CI/CD básico (GitHub Actions: test → build → deploy)
- [ ] Crear tenant de prueba + usuario admin de prueba
- [ ] Login funcionando end-to-end (web → API → BD)

### Entregable de la fase
✅ Puedes hacer login con email/password y ver "Hola, [nombre]" en la web.

---

## FASE 1 — Core: Inventario + Ventas

**Objetivo:** El flujo mínimo viable de una distribuidora: registrar productos, stock, y crear pedidos.

### Módulo: Productos y Categorías
- [ ] CRUD de productos con código, nombre, precio costo, precio venta
- [ ] Categorías de productos
- [ ] Búsqueda con autocompletar (pg_trgm)

### Módulo: Bodegas e Inventario
- [ ] CRUD de bodegas
- [ ] Asignación de stock inicial por bodega
- [ ] Registro de movimientos (entrada, salida, ajuste)
- [ ] Alerta visual de stock bajo
- [ ] Historial de movimientos con filtros

### Módulo: Clientes
- [ ] CRUD de clientes (RUT, nombre, contacto, dirección)
- [ ] Límite y días de crédito
- [ ] Historial de pedidos por cliente

### Módulo: Ventas (Pedidos)
- [ ] Crear pedido con items y cantidades
- [ ] Validación de stock disponible al confirmar
- [ ] Descuento a nivel de pedido e ítem
- [ ] Cálculo automático de subtotal, impuesto (IVA 19%), total
- [ ] Estados del pedido: borrador → confirmado → en_preparacion → entregado
- [ ] Numeración automática (PED-00001, PED-00002...)
- [ ] Búsqueda y filtros de pedidos

### Entregable de la fase
✅ Puedes crear un pedido para un cliente, que descuente el stock de la bodega, y marcarlo como entregado.

---

## FASE 2 — Operaciones: Compras + Flota + Empleados

**Objetivo:** Completar el ciclo operativo completo de una distribuidora.

### Módulo: Proveedores y Compras
- [ ] CRUD de proveedores
- [ ] Crear orden de compra con items
- [ ] Recepción parcial o total de orden (actualiza inventario automáticamente)
- [ ] Conciliación de facturas de proveedor
- [ ] Historial de compras por proveedor

### Módulo: Empleados
- [ ] CRUD de empleados (vinculado opcional a usuario del sistema)
- [ ] Asignación de roles y permisos por módulo
- [ ] Registro de cargo y fecha de ingreso

### Módulo: Flota de Vehículos
- [ ] CRUD de vehículos (patente, capacidad, estado)
- [ ] Registro de mantenimientos
- [ ] Alertas de mantenimiento próximo
- [ ] Asignación de rutas (pedido → vehículo → conductor)
- [ ] Seguimiento de estado de entrega

### Entregable de la fase
✅ Ciclo completo: compras ingresan al inventario, pedidos salen con vehículo asignado y se marcan como entregados.

---

## FASE 3 — Analytics

**Objetivo:** Visibilidad del negocio y primeras predicciones.

### Dashboards
- [ ] Dashboard principal con KPIs en tiempo real (WebSockets)
- [ ] Dashboard de ventas (gráficos temporales, comparativas)
- [ ] Dashboard de inventario (rotación, valorización, alertas)
- [ ] Dashboard de compras (gasto, proveedores, lead time)
- [ ] Dashboard de flota (entregas, tiempos)

### Reportes
- [ ] Exportación a Excel de todos los módulos
- [ ] Reporte de margen por producto
- [ ] Reporte de rentabilidad del período

### Predicciones (si hay ≥ 90 días de datos)
- [ ] Forecast de demanda por producto (Prophet)
- [ ] Simulación de temporada alta
- [ ] Detección básica de anomalías en ventas

### Entregable de la fase
✅ El dueño del negocio puede ver cuánto vendió hoy, qué productos están por acabarse, y una proyección de los próximos 30 días.

---

## FASE 4 — Aplicación Móvil Android (Flutter)

**Objetivo:** Versión móvil Android para operaciones de campo, construida en Flutter/Dart.

### Setup inicial Flutter
- [ ] Instalar Flutter SDK y configurar Android Studio
- [ ] Crear proyecto Flutter dentro del monorepo en `apps/mobile/`
- [ ] Configurar Riverpod para manejo de estado
- [ ] Configurar Dio con interceptores de autenticación JWT
- [ ] Configurar Hive para almacenamiento offline

### Funcionalidades móvil
- [ ] Login y autenticación (JWT con refresh token)
- [ ] Ver pedidos y rutas asignadas (chofer)
- [ ] Actualizar estado de entrega desde campo
- [ ] Firma digital del receptor en pantalla táctil
- [ ] Consulta de stock por bodega (bodeguero)
- [ ] Registrar movimiento de inventario desde bodega
- [ ] Escaneo de código de barras/QR de productos (mobile_scanner)
- [ ] Notificaciones push (alertas stock, nuevos pedidos asignados)
- [ ] Modo offline básico (Hive: ver últimos datos descargados sin conexión)
- [ ] Sincronización automática al recuperar conexión

### Distribución
- [ ] Generar APK firmado para distribución interna directa (sin Play Store)
- [ ] Opcional: publicar en Google Play Store ($25 USD cuenta única)

### Entregable de la fase
✅ Un chofer puede ver sus pedidos del día en el celular Android y marcar entregas completadas con firma digital. Un bodeguero puede registrar movimientos escaneando códigos de barra.

---

## FASE 5 — Integración SII Chile

**Objetivo:** Emisión de documentos tributarios electrónicos.

> **Prerrequisito:** Tener RUT de empresa, certificado digital, estar inscrito como DTE en el SII.

### Tareas
- [ ] Integración con API del SII (o proveedor intermediario como ACEPTA, Defontana API)
- [ ] Generación de boleta electrónica desde pedido
- [ ] Generación de factura electrónica (factura afecta 33)
- [ ] Nota de crédito electrónica (anulaciones/devoluciones)
- [ ] Libro de ventas automático (para declaración mensual)
- [ ] Libro de compras automático

### Nota sobre el proveedor intermediario
Conectarse directamente al SII es complejo (XML firmado con certificado digital, folios CAF). Evaluar primero integrarse con un **proveedor certificado** (ACEPTA, OpenDTE, Bsale API) que simplifique el proceso. Esto agrega un costo mensual pequeño pero ahorra meses de desarrollo.

---

## FASE 6 — Escala y Expansión

- [ ] Multi-rubro: adaptar módulos para retail, servicios, etc.
- [ ] Marketplace de integraciones (contabilidad, logística externa)
- [ ] App store de Thoth (módulos opcionales por tenant)
- [ ] Planes diferenciados (starter / pro / enterprise)
- [ ] API pública para integraciones de clientes
- [ ] Centro de datos regional (si la escala lo justifica)

---

## Prioridad de Deuda Técnica

Después de cada fase, antes de pasar a la siguiente:
1. Tests unitarios de las funciones críticas (cálculos de inventario, margen)
2. Tests de integración de los endpoints principales
3. Revisión de queries lentas (pg slow log)
4. Revisión de índices de BD
5. Actualización de dependencias con vulnerabilidades conocidas

---

*Ver [BUENAS_PRACTICAS.md](./BUENAS_PRACTICAS.md) para convenciones, seguridad y CI/CD.*
