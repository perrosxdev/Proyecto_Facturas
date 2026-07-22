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
FASE 6 · Scale         [ongoing]      · Optimización (LP/NLP), performance, multi-rubro, marketplace
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
- [ ] Motor de cálculo de precio de venta — costo, ganancia deseada, comisión de medio de pago e IVA (ver `LOGICA_NEGOCIO.md` sección 2)
- [ ] Estados del pedido: borrador → confirmado → en_preparacion → entregado
- [ ] Numeración automática (PED-00001, PED-00002...)
- [ ] Búsqueda y filtros de pedidos

### Entregable de la fase
✅ Puedes crear un pedido para un cliente, que descuente el stock de la bodega, y marcarlo como entregado, con el precio calculado correctamente según el motor de precios.

---

## FASE 2 — Operaciones: Compras + Flota + Empleados

**Objetivo:** Completar el ciclo operativo completo de una distribuidora.

### Módulo: Proveedores y Compras
- [ ] CRUD de proveedores
- [ ] Crear orden de compra con items
- [ ] Recepción parcial o total de orden (actualiza inventario automáticamente)
- [ ] Costo promedio ponderado (PMP) al recibir mercadería (ver `LOGICA_NEGOCIO.md` sección 4.3)
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

### KPIs y fórmulas de negocio
- [ ] Implementar los KPIs de márgenes, rotación, crédito (DSO) y rentabilidad definidos en `LOGICA_NEGOCIO.md` secciones 3–9
- [ ] Punto de equilibrio y contribución marginal por producto

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

**Objetivo:** Llevar Thoth de "funciona para un tenant" a "funciona como SaaS multi-cliente con capacidades avanzadas de decisión".

> **Prerrequisito:** Fase 3 (Analytics) debe estar sólida en producción — el módulo de optimización se apoya en costos, márgenes y predicciones de demanda ya calculados correctamente. Ver `OPTIMIZACION.md` sección 13.8 para el detalle de esta dependencia.

### Módulo de Optimización (ver `OPTIMIZACION.md` para el diseño completo)
- [ ] Motor LP — mezcla óptima de compra dado presupuesto y bodega (Simplex/HiGHS vía `scipy.optimize.linprog`)
- [ ] Restricciones `≤`, `≥` y `=` configurables por el usuario sin tocar código
- [ ] Precio sombra y rango de sensibilidad de restricciones y coeficientes (análisis de sensibilidad completo)
- [ ] Vista de método gráfico para modelos de 2 variables (explicabilidad)
- [ ] Motor NLP — precio óptimo con elasticidad de demanda (`SLSQP`/`trust-constr` para casos convexos, `differential_evolution`/`dual_annealing` para no convexos)
- [ ] Programación entera/mixta — asignación de vehículos a rutas y compra en múltiplos de lote (OR-Tools / PuLP)
- [ ] Optimización multi-período — plan de compras de varias semanas conectado a las predicciones de Prophet (`ANALYTICS.md`)
- [ ] Optimización bajo incertidumbre — escenarios pesimista/esperado/optimista usando `predicciones_cache`
- [ ] Comparación "dinero dejado en la mesa" — decisión real del usuario vs. óptimo calculado con los mismos datos
- [ ] Traducción completa a lenguaje simple en la UI (wizard de configuración, sin jerga matemática — ver `OPTIMIZACION.md` sección 10)
- [ ] Ejecución asíncrona vía BullMQ + WebSocket para modelos grandes
- [ ] Permisos (`admin`/`supervisor`) y límites de plan (`max_variables_optimizacion`, `max_corridas_por_mes`)

### Módulo de Planes y Facturación (ver `NEGOCIO_SAAS.md` para el diseño completo)
- [ ] Middleware de límites por plan — validar usuarios/productos/sucursales contra `tenants.limites` (base + expansiones compradas) antes de crear recursos
- [ ] Control de acceso a mejoras de plan (`modulos_activos`) — bloquear rutas de Flota/Analytics/Optimización si el módulo no está activo para el tenant
- [ ] Flujo de compra de expansiones (usuarios y sucursales por separado, unidad suelta o paquete) — acumulables sin límite
- [ ] Integración de cobro recurrente (Webpay Plus / Flow.cl) con soporte de montos variables por combinación de tenant (base + mejoras + expansiones)
- [ ] Build local descargable del plan Demo — target de build separado, sin Redis ni RLS multi-tenant (ver `NEGOCIO_SAAS.md` sección 2.3)

### Otras tareas de escala
- [ ] Multi-rubro: adaptar módulos para retail, servicios, etc.
- [ ] Marketplace de integraciones (contabilidad, logística externa)
- [ ] App store de Thoth (módulos opcionales por tenant)
- [ ] API pública para integraciones de clientes
- [ ] Centro de datos regional (si la escala lo justifica)

### Entregable de la fase
✅ Un dueño de distribuidora puede pedirle a Thoth "¿qué debería comprar este mes para maximizar mi ganancia?" y recibir una recomendación concreta, en lenguaje simple, con la opción de ver qué la limita y qué tan estable es la recomendación.

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
*Ver [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md) para las fórmulas de precio, margen e inventario implementadas en las Fases 1 y 3.*
*Ver [OPTIMIZACION.md](./OPTIMIZACION.md) para el diseño completo del módulo de optimización de la Fase 6.*
*Ver [NEGOCIO_SAAS.md](./NEGOCIO_SAAS.md) para el modelo de planes y facturación que el Módulo de Planes y Facturación de la Fase 6 implementa.*