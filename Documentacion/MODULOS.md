# MODULOS.md — Especificación Funcional de Módulos

---

## Resumen de Módulos y Dependencias

```
                    ┌──────────────┐
                    │   Productos  │ ← base de todo
                    └──────┬───────┘
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │  Bodegas   │  │  Clientes  │  │Proveedores │
    └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
          │               │               │
          ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │ Inventario │  │   Ventas   │  │  Compras   │
    └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
          └───────────────┼───────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
       ┌────────────┐          ┌────────────┐
       │   Flota    │          │ Empleados  │
       └────────────┘          └────────────┘
              │
              ▼
       ┌────────────┐
       │  Analytics │ ← consume todos los módulos
       └────────────┘
```

---

## Módulo 1: Gestión de Inventario

### Responsabilidades
- Mantener el stock actual por producto por bodega
- Registrar y auditar cada movimiento de inventario
- Alertar cuando el stock baje del mínimo configurado
- Valorizar el inventario (costo promedio ponderado)

### Reglas de negocio
1. El stock nunca puede quedar negativo (validar antes de confirmar salida)
2. Todo movimiento debe tener una referencia (origen: pedido, compra, ajuste manual)
3. Las transferencias entre bodegas generan DOS movimientos: salida de origen + entrada en destino
4. Los ajustes manuales requieren justificación (campo notas obligatorio)
5. Solo usuarios con rol `bodeguero`, `supervisor` o `admin` pueden registrar movimientos

### Tipos de movimiento
| Tipo | Cuándo | Afecta stock |
|------|--------|-------------|
| `entrada_compra` | Se recibe una orden de compra | + aumenta |
| `salida_venta` | Se confirma un pedido | - disminuye |
| `transferencia_salida` | Sale de bodega A | - disminuye en A |
| `transferencia_entrada` | Llega a bodega B | + aumenta en B |
| `ajuste_positivo` | Corrección de inventario (más) | + aumenta |
| `ajuste_negativo` | Corrección de inventario (menos), merma | - disminuye |
| `devolucion_cliente` | Cliente devuelve mercadería | + aumenta |
| `devolucion_proveedor` | Se devuelve al proveedor | - disminuye |

---

## Módulo 2: Gestión de Bodegas

### Responsabilidades
- Administrar las bodegas físicas de la distribuidora
- Controlar qué empleados tienen acceso a cada bodega
- Proveer vistas de stock consolidado y por bodega

### Reglas de negocio
1. Una distribuidora puede tener 1 o N bodegas
2. Cada bodega tiene un responsable asignado (usuario del sistema)
3. El inventario siempre pertenece a una bodega específica, nunca "en el aire"
4. No se puede eliminar una bodega con stock > 0 (solo desactivar)

---

## Módulo 3: Gestión de Ventas (Pedidos)

### Flujo del pedido

```
BORRADOR → CONFIRMADO → EN PREPARACIÓN → EN REPARTO → ENTREGADO
                                                  ↓
                                             CANCELADO (desde cualquier estado hasta EN REPARTO)
```

### Estados y transiciones
| Estado | Quién puede cambiar | Qué pasa en BD |
|--------|---------------------|----------------|
| `borrador` → `confirmado` | Vendedor, Admin | Se descuenta stock del inventario |
| `confirmado` → `en_preparacion` | Bodeguero, Admin | Se asigna bodega de despacho |
| `en_preparacion` → `en_reparto` | Bodeguero, Admin | Se crea registro de ruta |
| `en_reparto` → `entregado` | Chofer (móvil), Admin | Se registra firma y fecha |
| `* → cancelado` | Admin, Supervisor | Si confirmado+: se **devuelve** el stock |

### Reglas de negocio
1. Al confirmar el pedido: verificar stock disponible de **todos** los ítems antes de descontar ninguno (operación atómica)
2. Si el cliente tiene deuda vencida mayor a su límite de crédito: mostrar alerta (no bloquear automáticamente — decisión del vendedor)
3. El precio de venta en el ítem se "congela" al momento de confirmar (no cambia si el precio del producto cambia después)
4. Un pedido en estado `entregado` es inmutable (solo se puede crear nota de crédito/devolución)

---

## Módulo 4: Gestión de Compras

### Flujo de la orden de compra

```
BORRADOR → ENVIADA → RECIBIDA (total)
                 ↓
              PARCIAL → RECIBIDA (cuando llega el resto)
                 ↓
              CANCELADA
```

### Reglas de negocio
1. Al marcar la recepción (total o parcial), el stock aumenta automáticamente en la bodega de destino
2. La recepción parcial registra qué ítems llegaron y en qué cantidad — el resto queda pendiente
3. El precio de costo registrado en la orden actualiza el historial de precios del producto (útil para costo promedio ponderado)
4. Solo usuarios con permiso `compras:write` pueden crear y recibir órdenes

---

## Módulo 5: Gestión de Empleados

### Responsabilidades
- Registro de personal de la distribuidora
- Vinculación opcional con usuario del sistema (para acceso web/móvil)
- Control de roles y permisos por módulo

### Roles del sistema
| Rol | Acceso |
|-----|--------|
| `admin` | Todo — configuración, todos los módulos, reportes |
| `supervisor` | Todos los módulos operacionales + reportes, sin configuración |
| `vendedor` | Clientes + Ventas + consulta de inventario |
| `bodeguero` | Inventario + Bodegas + recepción de compras |
| `chofer` | Solo sus rutas asignadas (principalmente móvil) |

### Reglas de negocio
1. Un empleado puede existir en el sistema sin tener acceso (sin usuario vinculado)
2. Al desactivar un usuario, sus datos históricos se conservan
3. El cambio de rol de un usuario se audita (quién, cuándo, de qué rol a cuál)

---

## Módulo 6: Gestión de Flota

### Responsabilidades
- Administrar el parque de vehículos
- Asignar vehículos y conductores a pedidos
- Registrar el ciclo de vida y mantenimientos de cada vehículo
- Alertar sobre mantenciones próximas

### Estados de un vehículo
| Estado | Descripción |
|--------|-------------|
| `activo` | Disponible para asignación |
| `en_mantenimiento` | En taller — no asignable |
| `fuera_de_servicio` | Avería no planificada |
| `baja` | Dado de baja definitiva |

### Reglas de negocio
1. Solo vehículos en estado `activo` pueden ser asignados a rutas
2. Si un vehículo tiene mantenimiento programado en los próximos 7 días, se muestra advertencia al asignarlo
3. La capacidad de carga del vehículo se compara con el volumen del pedido (advertencia, no bloqueo)
4. Cada mantenimiento registrado actualiza la fecha de próximo mantenimiento

---

## Módulo 7: Analytics (ver ANALYTICS.md para detalle)

### Responsabilidades
- Agregar datos de todos los módulos en reportes y KPIs
- Proveer dashboards interactivos en tiempo real
- Calcular predicciones de demanda y simulaciones

### Principio de diseño
El módulo analytics es **solo lectura** — nunca modifica datos de operaciones. Lee de las tablas transaccionales y escribe solo en `predicciones_cache` y `audit_log`.

---

## Módulo 8: Integración SII (Fase 5)

### Responsabilidades
- Emisión de boletas electrónicas desde pedidos
- Emisión de facturas electrónicas (factura afecta 33)
- Emisión de notas de crédito (anulaciones)
- Generación automática del libro de ventas mensual

### Documentos tributarios a soportar
| DTE | Código SII | Cuándo se usa |
|-----|-----------|---------------|
| Boleta electrónica | 39 | Ventas a personas naturales sin crédito fiscal |
| Factura electrónica | 33 | Ventas a empresas con RUT (crédito fiscal IVA) |
| Nota de crédito | 61 | Anular/corregir boleta o factura emitida |
| Nota de débito | 56 | Cobros adicionales sobre documentos emitidos |

### Consideración importante
La integración SII no es trivial. Requiere:
- Empresa inscrita como contribuyente DTE en el SII
- Certificado digital vigente
- Folios CAF (Código de Autorización de Folios) para cada tipo de documento
- XML firmado con el certificado y enviado al SII en formato específico

**Recomendación:** Evaluar usar un proveedor certificado SII (ACEPTA, OpenDTE, Nubox) como intermediario para la primera versión. El costo es bajo (~$15–30 USD/mes) y simplifica enormemente la implementación.
