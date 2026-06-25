# ANALYTICS.md — Dashboards, KPIs, Predicciones y Simulaciones

---

## 1. Estructura del Módulo Analytics

El módulo analytics se divide en tres capas de complejidad creciente:

```
CAPA 1 — Reportes Básicos (disponibles desde el día 1)
  · Tablas y resúmenes estáticos
  · Exportación a Excel/PDF
  · Filtros por fecha, producto, cliente, etc.

CAPA 2 — Dashboards Interactivos con KPIs (disponibles desde el día 1)
  · Gráficos en tiempo real
  · Comparativas período anterior
  · Alertas automáticas

CAPA 3 — Predicciones y Simulaciones (requiere ~3 meses de datos históricos)
  · Forecasting de demanda
  · Simulación de escenarios
  · Detección de anomalías
```

---

## 2. KPIs por Módulo

### Ventas
| KPI | Cómo se calcula |
|-----|-----------------|
| Ingresos del período | SUM(total) de pedidos entregados |
| Ticket promedio | ingresos / número de pedidos |
| Tasa de conversión | pedidos entregados / pedidos creados |
| Clientes activos | clientes con al menos 1 pedido en 30 días |
| Top 10 clientes por volumen | ORDER BY total DESC LIMIT 10 |
| Top 10 productos más vendidos | SUM(cantidad) por producto |
| Ventas por canal / vendedor | GROUP BY vendedor_id |

### Inventario
| KPI | Cómo se calcula |
|-----|-----------------|
| Rotación de inventario | costo_ventas / ((inventario_inicial + inventario_final) / 2) |
| Días de inventario | (stock_actual / ventas_diarias_promedio) |
| Valor total del inventario | SUM(stock_actual * precio_costo) |
| Productos bajo mínimo | COUNT WHERE stock_actual <= stock_minimo |
| Merma del período | movimientos de tipo "ajuste" negativo |

### Compras
| KPI | Cómo se calcula |
|-----|-----------------|
| Gasto en compras del período | SUM(total) de órdenes recibidas |
| Proveedores más frecuentes | COUNT(ordenes) por proveedor |
| Lead time promedio | AVG(fecha_recibida - fecha_orden) |
| Costo promedio ponderado | útil para valorización de inventario |

### Flota
| KPI | Cómo se calcula |
|-----|-----------------|
| Entregas completadas vs fallidas | COUNT por estado de ruta |
| Tiempo promedio de entrega | AVG(fecha_entrega - fecha_salida) |
| Vehículos activos vs en mantención | COUNT por estado |
| Carga promedio por ruta | SUM(items del pedido) / COUNT(rutas) |

### Márgenes y Rentabilidad
| KPI | Cómo se calcula |
|-----|-----------------|
| Margen bruto | (ingresos - costo_ventas) / ingresos × 100 |
| Margen por producto | (precio_venta - precio_costo) / precio_venta × 100 |
| EBITDA simplificado | ingreso - compras - gastos operacionales registrados |

---

## 3. Stack Técnico de Analytics

### Python + FastAPI (servicio dedicado)

```python
# Librerías principales

pandas         # manipulación de datos
numpy          # cálculos numéricos
prophet        # forecasting de series de tiempo (Meta)
scikit-learn   # modelos ML (regresión, clustering, anomalías)
statsmodels    # modelos estadísticos, descomposición de series
sqlalchemy     # consultas a PostgreSQL
fastapi        # API del servicio analytics
pydantic       # validación de datos
openpyxl       # exportar a Excel
reportlab      # exportar a PDF
```

### ¿Por qué Prophet para forecasting?

Prophet (de Meta) es ideal para esta aplicación porque:
- Maneja estacionalidad múltiple (semana, mes, año)
- Funciona bien con **datos faltantes** (common en datos reales)
- Incorpora feriados y fechas especiales (Navidad, Fiestas Patrias)
- No requiere ingenieros de ML para configurar — los parámetros son interpretables
- Produce intervalos de confianza automáticamente

**Alternativa:** ARIMA/SARIMA es más clásico pero requiere más ajuste manual. Se puede usar como benchmark para comparar con Prophet.

---

## 4. Predicción de Demanda

### Flujo

```
1. Query SQL → ventas históricas por producto (mínimo 90 días)
2. Limpieza de datos (outliers, días sin venta)
3. Entrenamiento Prophet por producto (puede ser semanal/nocturno)
4. Predicción para los próximos 30/60/90 días
5. Resultado guardado en tabla predictions_cache
6. Dashboard consume cache → respuesta rápida
```

### Esquema de caché de predicciones

```sql
CREATE TABLE predicciones_cache (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    tipo            VARCHAR(50) NOT NULL,  -- demanda | stock | ventas
    entidad_id      UUID,                  -- producto_id, cliente_id, etc.
    horizonte_dias  INT NOT NULL,
    datos           JSONB NOT NULL,        -- array de {fecha, valor, intervalo_inf, intervalo_sup}
    generado_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valido_hasta    TIMESTAMPTZ NOT NULL,  -- TTL lógico
    modelo_version  VARCHAR(50)
);

ALTER TABLE predicciones_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON predicciones_cache USING (tenant_id = current_tenant_id());
```

### Ejemplo de respuesta de predicción

```json
{
  "producto_id": "uuid",
  "nombre": "Huevos blancos L (caja 360)",
  "horizonte": "90_dias",
  "prediccion": [
    { "fecha": "2026-07-01", "valor": 45.2, "min": 38.1, "max": 52.3 },
    { "fecha": "2026-07-02", "valor": 43.8, "min": 36.5, "max": 51.1 },
    ...
  ],
  "estacionalidad_detectada": ["semanal", "anual"],
  "confianza": 0.87,
  "dias_datos_usados": 180
}
```

---

## 5. Simulación de Escenarios

El usuario puede simular "¿qué pasa si...?" con sus datos históricos:

### Tipos de simulación

**Simulación de temporada alta**
```
Input:  período histórico de referencia (ej: Navidad 2025)
        factor de crecimiento esperado (ej: +40%)
Output: demanda proyectada por producto
        stock necesario para no quedar sin abasto
        inversión en compras recomendada
        alertas de productos con riesgo de quiebre
```

**Simulación de nuevo producto**
```
Input:  características del producto (precio, categoría similar)
        mercado objetivo (clientes actuales vs nuevos)
Output: demanda estimada basada en productos similares
        punto de equilibrio (break-even)
        impacto en rotación de inventario
```

**Simulación de cambio de precio**
```
Input:  producto, precio actual, precio nuevo
        elasticidad estimada (o usar histórico de cambios previos)
Output: impacto estimado en volumen de ventas
        impacto en margen bruto
        comparativa de ingresos esperados
```

---

## 6. Detección de Anomalías

El sistema puede alertar automáticamente sobre patrones inusuales:

- Caída de ventas de un cliente activo (posible pérdida del cliente)
- Incremento súbito en merma de un producto (posible robo o mal manejo)
- Pedido muy por encima del promedio histórico del cliente (fraude o error)
- Vehiculo con mucho más tiempo de ruta del promedio (problema en camino)

```python
# Usando Isolation Forest de scikit-learn para anomalías multivariadas
from sklearn.ensemble import IsolationForest

model = IsolationForest(contamination=0.05, random_state=42)
anomalias = model.fit_predict(datos_ventas_cliente)
# -1 = anomalía, 1 = normal
```

---

## 7. Reportes Exportables

| Reporte | Formato | Contenido |
|---------|---------|-----------|
| Ventas del período | Excel / PDF | Por fecha, producto, cliente, vendedor |
| Inventario actual | Excel | Stock, valorizado, bajo mínimo |
| Movimientos de bodega | Excel | Todos los movimientos con referencia |
| Órdenes de compra | PDF | Para enviar al proveedor |
| Rentabilidad por producto | Excel | Margen, rotación, contribución |
| Estado de flota | PDF | Vehículos, mantenciones, rutas del período |

Todos los reportes se generan como jobs asíncronos en la cola de Redis. El usuario recibe una notificación (WebSocket o email) cuando el reporte está listo para descargar.

---

## 8. Dashboard Principal — Diseño de Datos

```
┌──────────────────────────────────────────────────────────────┐
│  HOY · 25 Jun 2026                          [Último 30 días] │
├──────────────┬──────────────┬──────────────┬─────────────────┤
│ Ingresos     │ Pedidos      │ Stock bajo   │ Entregas hoy    │
│ $4.250.000   │ 38           │ ⚠ 3 productos│ 12 / 15         │
│ ↑12% vs ant. │ ↑5 vs ant.   │              │                 │
├──────────────┴──────────────┴──────────────┴─────────────────┤
│  [Gráfico: Ventas diarias últimos 30 días vs mismo período    │
│   año anterior]                                               │
├──────────────────────────────┬───────────────────────────────┤
│  Top 5 Productos             │  Pedidos por Estado           │
│  (barras horizontales)       │  (donut chart)                │
├──────────────────────────────┼───────────────────────────────┤
│  Alertas activas             │  Próximas entregas (hoy)      │
│  · Stock: Huevos rojos       │  · PED-0234 · Cliente X       │
│  · Mantención: Camión ABC    │  · PED-0235 · Cliente Y       │
└──────────────────────────────┴───────────────────────────────┘
```

---

*Ver [ROADMAP.md](./ROADMAP.md) para cuándo implementar cada capa de analytics.*
