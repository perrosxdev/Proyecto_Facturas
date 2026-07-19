# LOGICA_NEGOCIO.md — Lógica de Negocio, Fórmulas y Preguntas Clave · Thoth

> Este documento es la fuente de verdad de **qué calcula Thoth y por qué**. Cada fórmula
> aquí definida debe implementarse igual en `api-node` (cálculos en tiempo real, ej. precio
> de un pedido) y en `api-python` (cálculos agregados/analytics, ej. KPIs y predicciones).
> Si una fórmula cambia, se actualiza aquí primero y luego en el código — nunca al revés.

**Cómo está organizado:** cada sección tiene la fórmula general (aplicable a cualquier
distribuidora), casos borde a manejar, y un ejemplo aplicado al negocio de huevos como
caso de validación. Los ejemplos con huevos son ilustrativos — el motor de cálculo no debe
tener nada hardcodeado específico a huevos.

---

## Índice

1. [Glosario de Variables](#1-glosario-de-variables)
2. [Precios y Ganancia](#2-precios-y-ganancia)
3. [Márgenes y Rentabilidad](#3-márgenes-y-rentabilidad)
4. [Inventario](#4-inventario)
5. [Ventas](#5-ventas)
6. [Crédito y Cobranza](#6-crédito-y-cobranza)
7. [Compras y Proveedores](#7-compras-y-proveedores)
8. [Flota y Logística](#8-flota-y-logística)
9. [Rentabilidad del Negocio Completo](#9-rentabilidad-del-negocio-completo)
10. [Redondeo y Moneda (Chile)](#10-redondeo-y-moneda-chile)
11. [Preguntas Clave que Thoth Debe Poder Responder](#11-preguntas-clave-que-thoth-debe-poder-responder)
12. [Ejemplo Integral Aplicado — Distribuidora de Huevos](#12-ejemplo-integral-aplicado--distribuidora-de-huevos)

---

## 1. Glosario de Variables

| Variable | Descripción |
|----------|-------------|
| `Cn` | Costo neto (sin IVA) de un producto o insumo |
| `Ci` | Costo con IVA incluido |
| `Ct` | Costo neto total (suma de todos los costos, normalizados a netos) |
| `Pn` | Precio neto (sin IVA) |
| `Pf` | Precio final de venta (con IVA, listo para cobrar al cliente) |
| `G` | Ganancia neta deseada (monto fijo, en pesos) |
| `Gm` | Ganancia como markup deseado (porcentaje sobre el costo) |
| `i` | Tasa de IVA vigente en Chile — `0.19` |
| `c` | Comisión efectiva del medio de pago (decimal) |
| `d` | Descuento aplicado (decimal, ej. `0.10` = 10%) |
| `Q` | Cantidad (unidades, cajas, kg, etc.) |
| `SS` | Stock de seguridad |
| `PR` | Punto de reorden (reorder point) |
| `LT` | Lead time — días entre generar la orden de compra y recibir la mercadería |
| `DP` | Demanda promedio diaria (unidades vendidas por día) |
| `CMV` | Costo de mercadería vendida (costo de ventas) |
| `PMP` | Precio promedio ponderado (costo promedio ponderado de inventario) |
| `DSO` | Days Sales Outstanding — días promedio que tarda un cliente en pagar |
| `Z` | Factor estadístico de nivel de servicio deseado |
| `σ` | Desviación estándar (variabilidad) de una medición |

---

## 2. Precios y Ganancia

> Esta sección reemplaza y extiende `Formulas_negocios.md` — ese archivo se mantiene
> como referencia rápida, pero las fórmulas completas y sus casos borde viven aquí.

### 2.1 Comisión efectiva del medio de pago (`c`)

**Si la comisión publicada NO incluye IVA:**

```math
c = \text{comisión publicada} \times (1+i)
```

**Si la comisión publicada YA incluye IVA:**

```math
c = \text{comisión publicada}
```

**Caso borde — comisión mixta según monto o plazo:** algunos proveedores (ej. tarjetas de
crédito a cuotas) cambian `c` según el número de cuotas. Thoth debe permitir configurar
`c` por método de pago, no un valor único global.

**Caso borde — pago sin comisión (efectivo, transferencia):** `c = 0`. La fórmula de precio
final se reduce a `Pf = Pn(1+i)` sin dividir por `(1-c)`.

---

### 2.2 Precio final de venta — costo neto (sin IVA)

```math
Pn = Cn + G
```

```math
Pf = \frac{Pn(1+i)}{1-c}
```

**Forma resumida:**

```math
Pf = \frac{(Cn+G)(1+i)}{1-c}
```

### 2.3 Precio final de venta — costo con IVA incluido

```math
Ct = \frac{Ci}{1+i}
```

```math
Pn = Ct + G
```

```math
Pf = \frac{Pn(1+i)}{1-c}
```

**Forma resumida:**

```math
Pf = \frac{\left(\dfrac{Ci}{1+i}+G\right)(1+i)}{1-c}
```

### 2.4 Precio final de venta — costos mixtos (con y sin IVA)

```math
Ct = Cn + \frac{Ci}{1+i}
```

```math
Pn = Ct + G
```

```math
Pf = \frac{Pn(1+i)}{1-c}
```

**Forma resumida:**

```math
Pf = \frac{\left(Cn+\dfrac{Ci}{1+i}+G\right)(1+i)}{1-c}
```

### 2.5 Precio final usando markup en vez de ganancia fija

Cuando el negocio define la ganancia como **porcentaje sobre el costo** (markup) en vez de
un monto fijo:

```math
G = Ct \times Gm
```

```math
Pf = \frac{Ct(1+Gm)(1+i)}{1-c}
```

**Diferencia entre markup y margen (no confundir):**

```math
Gm = \frac{G}{Ct} \quad\text{(markup — sobre el costo)}
```

```math
\text{margen} = \frac{G}{Pf} \quad\text{(margen — sobre el precio de venta)}
```

> Si el negocio pide "quiero 30% de margen", **no es lo mismo** que "30% de markup".
> Ver conversión exacta entre ambos en la sección 3.1.

### 2.6 Precio con descuento aplicado

```math
Pf_{\text{descuento}} = Pf \times (1-d)
```

**Caso borde — descuento que vuelve el precio menor al costo:** Thoth debe alertar
(no bloquear, según regla de negocio de `MODULOS.md`) si:

```math
Pf_{\text{descuento}} < Ct(1+i)
```

Esto significa que se está vendiendo bajo el costo con IVA — puede ser una decisión
consciente (liquidación) pero el sistema debe advertirlo.

### 2.7 Precio mínimo de venta (piso de precio)

El precio bajo el cual el negocio pierde dinero, considerando la comisión del medio de pago:

```math
Pf_{\text{mínimo}} = \frac{Ct(1+i)}{1-c}
```

Esto es la fórmula de la sección 2.2–2.4 con `G = 0`. Útil para que el vendedor sepa hasta
dónde puede negociar sin generar pérdida.

### 2.8 Ingeniería inversa — costo máximo aceptable dado un precio fijo de mercado

Cuando el precio de venta está fijado por el mercado (competencia) y se quiere saber el
costo máximo aceptable para lograr una ganancia mínima:

```math
Ct_{\text{máximo}} = \frac{Pf(1-c)}{1+i} - G
```

### 2.9 Casos borde generales de precios

| Caso | Qué debe hacer Thoth |
|------|----------------------|
| `c ≥ 1` (comisión ≥ 100%, error de configuración) | Rechazar, es matemáticamente inválido — división por cero o negativo |
| `Ct = 0` (producto gratuito, ej. promoción) | Permitir, `Pf` puede ser `0` o solo cubrir IVA/comisión si se regala con cargo |
| `G` negativa | Permitir con advertencia — vender a pérdida es una decisión válida de negocio (ej. producto próximo a vencer) |
| Producto con múltiples proveedores y costos distintos | Usar **costo promedio ponderado** (sección 4.3), no el último costo ingresado |
| Cambio de IVA (`i`) a futuro | `i` debe ser una variable de configuración del tenant, nunca un valor hardcodeado en el código |

---

## 3. Márgenes y Rentabilidad

### 3.1 Conversión entre Markup y Margen

```math
\text{margen} = \frac{Gm}{1+Gm} \quad\text{(convertir markup a margen)}
```

```math
Gm = \frac{\text{margen}}{1-\text{margen}} \quad\text{(convertir margen a markup)}
```

**Ejemplo:** un markup del 50% (`Gm = 0.5`) equivale a un margen de `0.5/1.5 = 33.3%`,
no a un margen del 50%. Confundir ambos es un error común que hace que el negocio gane
menos de lo planeado.

### 3.2 Margen bruto

```math
\text{margen bruto} = \frac{\text{ingresos} - CMV}{\text{ingresos}} \times 100
```

### 3.3 Margen bruto por producto

```math
\text{margen producto} = \frac{\text{precio venta} - \text{precio costo}}{\text{precio venta}} \times 100
```

### 3.4 Margen neto (después de gastos operacionales)

```math
\text{margen neto} = \frac{\text{ingresos} - CMV - \text{gastos operacionales}}{\text{ingresos}} \times 100
```

### 3.5 Contribución marginal por producto

Útil para decidir qué productos priorizar cuando hay stock limitado o capacidad de reparto
limitada:

```math
\text{contribución marginal} = \text{precio venta} - \text{costo variable unitario}
```

### 3.6 Punto de equilibrio (break-even)

**En unidades:**

```math
Q_{\text{equilibrio}} = \frac{\text{costos fijos}}{\text{contribución marginal unitaria}}
```

**En pesos:**

```math
\text{Ingresos}_{\text{equilibrio}} = \frac{\text{costos fijos}}{\text{margen bruto \%}}
```

**Caso borde:** si `contribución marginal unitaria ≤ 0` (se vende bajo el costo variable),
el punto de equilibrio es matemáticamente infinito — nunca se alcanza sin importar el
volumen. Thoth debe detectar y alertar este caso.

---

## 4. Inventario

### 4.1 Rotación de inventario

```math
\text{rotación} = \frac{CMV}{\text{inventario promedio}}
```

```math
\text{inventario promedio} = \frac{\text{inventario inicial} + \text{inventario final}}{2}
```

### 4.2 Días de inventario (Days Inventory Outstanding)

```math
\text{días inventario} = \frac{365}{\text{rotación}}
```

o directamente:

```math
\text{días inventario} = \frac{\text{stock actual}}{\text{demanda promedio diaria}}
```

**Caso borde — demanda promedio diaria = 0:** producto sin ventas recientes. No dividir por
cero — mostrar "sin rotación" o "∞ días" en vez de un error, y sugerirlo como candidato a
liquidación o descontinuación.

### 4.3 Costo Promedio Ponderado (PMP / valorización de inventario)

Cuando llega mercadería nueva a un costo distinto del stock existente:

```math
PMP_{\text{nuevo}} = \frac{\text{stock actual} \times PMP_{\text{actual}} + \text{cantidad ingresada} \times \text{costo ingresado}}{\text{stock actual} + \text{cantidad ingresada}}
```

Este es el valor que debe actualizarse en `productos.precio_costo` al recibir una orden de
compra (ver `API.md` sección de recepción de compras).

### 4.4 Valor total del inventario

```math
\text{valor inventario} = \sum_{k=1}^{n} \big(\text{stock actual}_k \times PMP_k\big)
```

### 4.5 Punto de reorden (Reorder Point)

Cuándo generar una nueva orden de compra para no quedar sin stock:

```math
PR = (DP \times LT) + SS
```

### 4.6 Stock de seguridad (Safety Stock)

Cubre la variabilidad de la demanda y del tiempo de entrega del proveedor:

```math
SS = Z \times \sigma_{\text{demanda}} \times \sqrt{LT}
```

Donde `Z` es el factor de nivel de servicio deseado (ej. `1.65` para 95% de nivel de
servicio) y `σ_demanda` es la desviación estándar de la demanda diaria histórica.

**Versión simplificada (sin estadística, para tenants con poco historial):**

```math
SS = DP \times \text{días de colchón manual}
```

Donde `días de colchón manual` es un número fijo que el usuario configura (ej. 3 días)
hasta que haya suficiente historial (≥90 días) para calcular `σ_demanda` con Prophet/
scikit-learn (ver `ANALYTICS.md`).

### 4.7 Stock máximo recomendado

```math
\text{stock máximo} = PR + Q_{\text{lote de compra}}
```

### 4.8 Merma

```math
\text{merma \%} = \frac{\text{unidades ajuste negativo}}{\text{unidades vendidas período}} \times 100
```

### 4.9 Casos borde de inventario

| Caso | Qué debe hacer Thoth |
|------|----------------------|
| Producto nuevo sin historial de ventas | `DP` no calculable — usar valor manual ingresado por el usuario o 0 |
| Transferencia entre bodegas | No afecta `CMV` ni rotación global del tenant, solo redistribuye stock |
| Producto perecible (ej. huevos) con fecha de vencimiento | La merma por vencimiento se registra como `ajuste_negativo` con nota obligatoria — ver Módulo 3 en `MODULOS.md` |
| Stock negativo | Nunca permitido — bloqueado a nivel de transacción (`BASE_DE_DATOS.md`) |

---

## 5. Ventas

### 5.1 Ticket promedio

```math
\text{ticket promedio} = \frac{\text{ingresos período}}{\text{número de pedidos}}
```

### 5.2 Tasa de conversión

```math
\text{conversión} = \frac{\text{pedidos entregados}}{\text{pedidos creados}} \times 100
```

### 5.3 Frecuencia de compra de un cliente

```math
\text{frecuencia} = \frac{\text{número de pedidos del cliente}}{\text{meses activo como cliente}}
```

### 5.4 Valor de vida del cliente (LTV) — simplificado

```math
LTV = \text{ticket promedio cliente} \times \text{frecuencia mensual} \times \text{margen bruto \%} \times \text{vida útil estimada (meses)}
```

> `vida útil estimada` puede fijarse manualmente al inicio (ej. 24 meses) hasta tener
> suficiente historial para calcularla con tasa de retención real.

### 5.5 Cálculo de totales de un pedido

```math
\text{subtotal} = \sum_{k=1}^{n} \big(\text{cantidad}_k \times \text{precio unitario}_k\big)
```

```math
\text{neto} = \text{subtotal} - \text{descuento}
```

```math
IVA = \text{neto} \times 0.19
```

```math
\text{total} = \text{neto} + IVA
```

**Regla de negocio (ya definida en `MODULOS.md`):** el precio unitario se congela al
confirmar el pedido — cambios posteriores en `productos.precio_venta` no afectan pedidos ya
confirmados.

### 5.6 Casos borde de ventas

| Caso | Qué debe hacer Thoth |
|------|----------------------|
| Pedido con un solo ítem y descuento 100% | Total = 0. Válido para bonificaciones/regalos — pero requiere justificación en `notas` |
| Cliente nuevo sin historial (LTV) | Mostrar "sin datos suficientes" en vez de 0 |
| Devolución parcial de un pedido entregado | Genera nota de crédito y `movimiento_inventario` de tipo `devolucion_cliente` — no se edita el pedido original |

---

## 6. Crédito y Cobranza

### 6.1 Deuda actual de un cliente

```math
\text{deuda actual} = \sum \text{total pedidos facturados no pagados}
```

### 6.2 Crédito disponible

```math
\text{crédito disponible} = \text{límite de crédito} - \text{deuda actual}
```

**Regla de negocio (`MODULOS.md`):** si `crédito disponible < total del nuevo pedido`, se
muestra alerta visual — no se bloquea automáticamente, es decisión del vendedor.

### 6.3 Días de crédito vencidos

```math
\text{días vencido} = \text{fecha actual} - (\text{fecha pedido} + \text{días crédito cliente})
```

Si `días vencido > 0`, el monto de ese pedido está vencido.

### 6.4 DSO — Days Sales Outstanding (promedio de cobro)

```math
DSO = \frac{\text{cuentas por cobrar}}{\text{ingresos a crédito del período}} \times \text{días del período}
```

Mide en promedio cuántos días tarda el negocio en cobrar sus ventas a crédito. Un DSO
creciente en el tiempo es señal de problemas de cobranza.

### 6.5 Score de riesgo de crédito — simplificado

Modelo básico basado en reglas (no ML) para una primera versión, ponderando:

```math
\text{riesgo} = w_1 \cdot \%\text{pedidos pagados fuera de plazo} + w_2 \cdot \frac{1}{\text{antigüedad del cliente (meses)}} + w_3 \cdot \frac{\text{deuda promedio}}{\text{límite de crédito}}
```

Salida sugerida: `bajo | medio | alto`. Esto puede evolucionar a un modelo de
`scikit-learn` en Fase 3 (ver `ANALYTICS.md`) cuando haya suficiente historial de pagos.

---

## 7. Compras y Proveedores

### 7.1 Lead time promedio de un proveedor

```math
\text{lead time promedio} = \text{AVG}(\text{fecha recibida} - \text{fecha orden})
```

### 7.2 Cantidad económica de pedido (EOQ) — opcional, para automatizar sugerencias de compra

```math
EOQ = \sqrt{\frac{2 \, D \, S}{H}}
```

Donde `D` es la demanda anual del producto, `S` el costo fijo de hacer una orden de compra
(administrativo), y `H` el costo de mantener una unidad en inventario por año (bodegaje,
capital inmovilizado).

> Esta fórmula es de nivel avanzado — no es requisito para Fase 1/2, pero queda documentada
> para cuando el módulo de compras se automatice (Fase 6 — Escala).

### 7.3 Costo total de una orden de compra

```math
\text{total orden} = \sum_{k=1}^{n} \big(\text{cantidad}_k \times \text{costo unitario}_k\big) + \text{costos adicionales}
```

`costos adicionales` = flete, aranceles, etc., si se decide prorratearlos al costo del
producto (afecta el PMP de la sección 4.3).

### 7.4 Casos borde de compras

| Caso | Qué debe hacer Thoth |
|------|----------------------|
| Recepción parcial | Solo actualiza PMP con la cantidad efectivamente recibida a ese costo |
| Proveedor con lead time muy variable | Usar `σ_lead_time` en el cálculo de `SS` (sección 4.6) en vez de un `LT` fijo, cuando haya historial suficiente |
| Devolución a proveedor | Movimiento `devolucion_proveedor`, no afecta el PMP retroactivamente |

---

## 8. Flota y Logística

### 8.1 Costo por entrega

```math
\text{costo por entrega} = \frac{\text{costo operativo de la ruta en el período}}{\text{número de entregas del período}}
```

`costo operativo de la ruta` incluye combustible, mantención prorrateada, sueldo chofer
prorrateado.

### 8.2 Costo por kilómetro

```math
\text{costo por km} = \frac{\text{costo operativo del vehículo en el período}}{\text{km recorridos en el período}}
```

### 8.3 Capacidad utilizada de un vehículo

```math
\text{capacidad utilizada \%} = \frac{\text{carga asignada}}{\text{capacidad máxima del vehículo}} \times 100
```

Regla ya definida en `MODULOS.md`: advertencia (no bloqueo) si supera el 100%.

### 8.4 Tiempo promedio de entrega

```math
\text{tiempo promedio} = \text{AVG}(\text{fecha entrega} - \text{fecha salida})
```

### 8.5 Tasa de entregas fallidas

```math
\text{tasa fallidas} = \frac{\text{entregas fallidas}}{\text{entregas totales}} \times 100
```

---

## 9. Rentabilidad del Negocio Completo

### 9.1 EBITDA simplificado

```math
EBITDA = \text{ingresos} - CMV - \text{gastos operacionales registrados}
```

> No incluye depreciación, intereses ni impuestos — para eso se requiere un módulo
> contable completo, fuera del alcance actual de Thoth.

### 9.2 Rentabilidad por bodega

```math
\text{rentabilidad bodega} = \frac{\text{ingresos bodega} - CMV_{\text{bodega}} - \text{costos operativos bodega}}{\text{ingresos bodega}} \times 100
```

Permite comparar el desempeño de múltiples puntos de distribución — relevante dado el
diseño multi-bodega descrito en `README.md` y `MODULOS.md`.

### 9.3 Rentabilidad por vendedor

```math
\text{rentabilidad vendedor} = \text{margen bruto generado por el vendedor} - \text{comisiones pagadas}
```

### 9.4 Costo total de servir a un cliente (Cost-to-Serve) — avanzado

```math
\text{costo servir cliente} = \big(\text{costo por entrega} \times \text{entregas al cliente}\big) + \text{costo administrativo prorrateado} + \text{costo financiero por crédito otorgado}
```

Útil para detectar clientes que, aunque compran mucho, generan poca o ninguna rentabilidad
real por el costo de atenderlos (muchas entregas pequeñas, crédito largo, etc.).

---

## 10. Redondeo y Moneda (Chile)

El peso chileno (CLP) **no tiene decimales** en el uso comercial estándar. Reglas:

- Todos los cálculos intermedios (`Pn`, `Ct`, márgenes) pueden mantener decimales
  internamente para precisión, pero el precio final mostrado y cobrado (`Pf`) **siempre**
  se redondea a entero.
- Redondeo estándar: al entero más cercano (*round-half-up*), no truncar.
- Redondeo "psicológico" opcional: redondear a la centena o el múltiplo de $10/$50 más
  cercano hacia arriba para precios más "limpios" (ej. `$36.176 → $36.200`). Esto es una
  decisión de negocio configurable por tenant, no una regla obligatoria del sistema.
- Nunca usar tipos de punto flotante (`float`/`double`) para dinero en el backend — usar
  `NUMERIC(12,2)` en PostgreSQL (ya definido en `BASE_DE_DATOS.md`) y librerías de
  precisión decimal en el código (evitar errores de redondeo acumulados en JavaScript).

---

## 11. Preguntas Clave que Thoth Debe Poder Responder

Esta lista es el criterio de éxito funcional del sistema — si Thoth no puede responder
estas preguntas con datos reales, el módulo correspondiente no está completo.

### Precio y rentabilidad
- [ ] ¿Cuál es el precio de venta correcto para este producto dado su costo, la ganancia deseada y el medio de pago?
- [ ] ¿Estoy vendiendo algún producto bajo el costo (margen negativo)?
- [ ] ¿Cuál es mi margen bruto real este mes vs el mes anterior?
- [ ] ¿Qué productos me dejan más ganancia por unidad vendida? ¿Y en total?
- [ ] ¿Cuántas unidades necesito vender este mes para cubrir mis costos fijos (punto de equilibrio)?

### Inventario
- [ ] ¿Qué productos están por debajo de su stock mínimo ahora mismo?
- [ ] ¿Cuándo debo generar la próxima orden de compra de cada producto (punto de reorden)?
- [ ] ¿Cuánto vale mi inventario actual, valorizado a costo promedio?
- [ ] ¿Qué productos rotan poco y están inmovilizando capital?
- [ ] ¿Cuánta merma he tenido este período y en qué productos?

### Ventas
- [ ] ¿Cuáles son mis ingresos hoy / esta semana / este mes, comparado con el período anterior?
- [ ] ¿Quiénes son mis mejores clientes por volumen y por rentabilidad (no son siempre los mismos)?
- [ ] ¿Qué clientes han bajado su frecuencia de compra (riesgo de pérdida)?
- [ ] ¿Cuál es mi ticket promedio y cómo ha evolucionado?

### Crédito
- [ ] ¿Qué clientes tienen deuda vencida y por cuánto?
- [ ] ¿Cuánto crédito le queda disponible a un cliente antes de alertar (no bloquear) un nuevo pedido?
- [ ] ¿Cuál es mi DSO y está empeorando?

### Compras
- [ ] ¿Qué proveedor tiene mejor lead time y confiabilidad?
- [ ] ¿Cuánto he gastado en compras este período por proveedor?
- [ ] ¿El costo de mis insumos ha subido y debería ajustar precios de venta?

### Flota
- [ ] ¿Cuánto me cuesta cada entrega en promedio?
- [ ] ¿Qué vehículo/ruta tiene más entregas fallidas o tiempos más largos?
- [ ] ¿Qué vehículos necesitan mantención pronto?

### Predicción (Fase 3, con ≥90 días de datos)
- [ ] ¿Cuánto voy a vender de cada producto en los próximos 30/60/90 días?
- [ ] Si tengo un evento de temporada alta (ej. Navidad, Fiestas Patrias), ¿cuánto stock necesito y cuánto debo invertir en compras?
- [ ] ¿Hay algún patrón inusual (anomalía) en ventas, merma o entregas que merezca revisión?

---

## 12. Ejemplo Integral Aplicado — Distribuidora de Huevos

Este ejemplo conecta varias fórmulas de este documento usando el caso de validación real
del proyecto (distribuidora de huevos), con números ilustrativos.

**Datos base:**

```
Producto:             Caja de huevos blancos L (360 unidades)
Costo con IVA (Ci):   $27.205
Ganancia deseada (G): $7.000
Comisión TUU (c):     0.017731  (1,49% + IVA)
IVA (i):              0.19
Stock actual:         120 cajas
Demanda promedio:     18 cajas/día
Lead time proveedor:  2 días
Stock de seguridad:   36 cajas (2 días de colchón manual)
```

**1. Precio de venta (sección 2.3):**

```math
Ct = \frac{27.205}{1.19} = 22.861
```

```math
Pn = 22.861 + 7.000 = 29.861
```

```math
Pf = \frac{29.861 \times 1.19}{1 - 0.017731} = 36.176 \;\rightarrow\; \$36.200 \text{ (redondeado)}
```

**2. Margen real vs markup (sección 3.1):**

```math
Gm = \frac{7.000}{22.861} = 30.6\% \quad\text{(markup)}
```

```math
\text{margen} = \frac{0.306}{1.306} = 23.4\%
```

> Aunque el markup es 30,6%, el margen real sobre el precio de venta es 23,4%.

**3. Punto de reorden (sección 4.5):**

```math
PR = (18 \times 2) + 36 = 72 \text{ cajas}
```

> Con 120 cajas en stock, todavía no se activa la alerta de reorden. Se activará cuando el
> stock baje a 72 cajas o menos.

**4. Días de inventario (sección 4.2):**

```math
\text{días inventario} = \frac{120}{18} = 6.7 \text{ días de cobertura}
```

**5. Punto de equilibrio (sección 3.6), asumiendo costos fijos mensuales de $1.200.000:**

```math
\text{contribución marginal unitaria} = 36.200 - 27.205 = 8.995
```

```math
Q_{\text{equilibrio}} = \frac{1.200.000}{8.995} \approx 134 \text{ cajas/mes}
```

> El negocio necesita vender ~134 cajas al mes solo para cubrir costos fijos, antes de
> generar ganancia neta real.

Este mismo flujo de fórmulas aplica sin modificación a cualquier otro rubro de
distribución (bebidas, abarrotes, insumos de limpieza, etc.) — el motor de cálculo de
Thoth no debe tener nada específico a huevos hardcodeado en el código.

---

*Ver [Formulas_negocios.md](./Formulas_negocios.md) para la referencia rápida original de precios.*
*Ver [ANALYTICS.md](./ANALYTICS.md) para cómo estos KPIs se muestran en dashboards.*
*Ver [MODULOS.md](./MODULOS.md) para las reglas de negocio que rigen cuándo se aplica cada fórmula.*
*Ver [BASE_DE_DATOS.md](./BASE_DE_DATOS.md) para el esquema donde viven estos datos.*