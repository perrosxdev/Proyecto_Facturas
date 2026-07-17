# Cálculo de Precio de Venta

Este documento describe las fórmulas utilizadas para calcular el precio de venta de un producto considerando:

- Costo del producto.
- Ganancia neta deseada.
- IVA.
- Comisión del medio de pago.

---

# Variables

| Variable | Descripción |
|----------|-------------|
| `Cn` | Costos sin IVA (netos) |
| `Ci` | Costos con IVA |
| `Ct` | Costo neto total |
| `Pn` | Precio neto |
| `Pf` | Precio final de venta |
| `G` | Ganancia neta deseada |
| `i` | Tasa de IVA (ej.: `0.19`) |
| `c` | Comisión efectiva del medio de pago (en decimal) |

---

# Comisión efectiva (`c`)

La variable `c` representa la **comisión efectiva** aplicada por el medio de pago sobre el monto de la venta.

## Si la comisión publicada NO incluye IVA

Primero debe calcularse la comisión efectiva:

```math
c = \text{Comisión} \times (1+i)
```

### Ejemplo

```text
Comisión publicada = 1,49%
IVA = 19%
```

```text
c = 0.0149 × 1.19
c = 0.017731
```

## Si la comisión publicada YA incluye IVA

La comisión efectiva corresponde directamente al valor informado.

Ejemplo:

```text
Comisión publicada = 2,10% IVA incluido

c = 0.021
```

> **Nota:** Algunos proveedores utilizan una misma comisión para débito y crédito, mientras que otros poseen una comisión distinta para cada tipo de pago. En esos casos, basta con utilizar el valor de `c` correspondiente al medio de pago utilizado.

---

# Opción 1: El costo NO incluye IVA

Utilice esta opción cuando el costo ingresado corresponda al valor **neto**.

## Paso 1: Calcular el precio neto

```math
Pn = Cn + G
```

## Paso 2: Calcular el precio final

```math
Pf = \frac{Pn(1+i)}{1-c}
```

### Fórmula resumida

```math
Pf = \frac{(Cn+G)(1+i)}{1-c}
```

---

# Opción 2: El costo SÍ incluye IVA

Utilice esta opción cuando el costo ingresado ya incluya IVA.

## Paso 1: Obtener el costo neto

```math
Ct = \frac{Ci}{1+i}
```

## Paso 2: Calcular el precio neto

```math
Pn = Ct + G
```

## Paso 3: Calcular el precio final

```math
Pf = \frac{Pn(1+i)}{1-c}
```

### Fórmula resumida

```math
Pf = \frac{\left(\frac{Ci}{1+i}+G\right)(1+i)}{1-c}
```

---

# Opción 3: Costos mixtos (con y sin IVA)

Utilice esta opción cuando algunos costos incluyan IVA y otros no.

## Paso 1: Obtener el costo neto total

```math
Ct = Cn + \frac{Ci}{1+i}
```

Donde:

- `Cn` corresponde a la suma de todos los costos sin IVA.
- `Ci` corresponde a la suma de todos los costos con IVA.

## Paso 2: Calcular el precio neto

```math
Pn = Ct + G
```

## Paso 3: Calcular el precio final

```math
Pf = \frac{Pn(1+i)}{1-c}
```

### Fórmula resumida

```math
Pf =
\frac{\left(Cn+\frac{Ci}{1+i}+G\right)(1+i)}
{1-c}
```

---

# ¿Por qué se divide por (1 - c)?

La comisión del medio de pago se descuenta del monto pagado por el cliente.

Ejemplo:

```text
Cliente paga         $100,00
Comisión              $1,77
Monto recibido       $98,23
```

Lo anterior equivale a:

```math
100(1-c)
```

Por ello, para recibir exactamente el monto esperado, el precio debe calcularse dividiendo por:

```math
1-c
```

---

# Ejemplos de comisión efectiva

| Medio de pago | Comisión publicada | ¿Incluye IVA? | `c` |
|---------------|-------------------:|:-------------:|----:|
| Efectivo | 0% | Sí | 0 |
| Transferencia | 0% | Sí | 0 |
| TUU | 1,49% | No | 0.017731 |
| Otro proveedor | 2,10% | Sí | 0.021000 |

---

# Valores utilizados en los ejemplos

| Concepto | Valor |
|----------|------:|
| IVA (`i`) | 19% |
| Comisión (`c`) | 0.017731 |

---

# Ejemplo 1: Costo con IVA

Datos:

```text
Costo con IVA (Ci) = $27.205
Ganancia (G)       = $7.000
Comisión (c)       = 0.017731
```

### Obtener costo neto

```math
Ct=\frac{27.205}{1.19}=22.861
```

### Obtener precio neto

```math
Pn=22.861+7.000=29.861
```

### Obtener precio final

```math
Pf=\frac{29.861(1.19)}{1-0.017731}=36.176
```

**Precio recomendado:** **$36.176**

---

# Ejemplo 2: Costos mixtos

Datos:

| Concepto | Valor |
|----------|------:|
| Caja de huevos (con IVA) | $27.205 |
| Envases (sin IVA) | $2.500 |
| Etiquetas (sin IVA) | $800 |
| Ganancia | $7.000 |
| Comisión | 0.017731 |

### Obtener costo neto total

```math
Ct=
2500+800+\frac{27205}{1.19}
=26.161
```

### Obtener precio neto

```math
Pn=26.161+7.000=33.161
```

### Obtener precio final

```math
Pf=
\frac{33.161(1.19)}
{1-0.017731}
\approx40.200
```

**Precio recomendado:** **$40.200**

---

# Resumen

## Si todos los costos son netos

```math
Pf=\frac{(Cn+G)(1+i)}{1-c}
```

## Si todos los costos incluyen IVA

```math
Pf=\frac{\left(\frac{Ci}{1+i}+G\right)(1+i)}{1-c}
```

## Si existen costos con y sin IVA

```math
Pf=
\frac{\left(Cn+\frac{Ci}{1+i}+G\right)(1+i)}
{1-c}
```

---

# Observaciones

- Estas fórmulas asumen que el contribuyente recupera el crédito fiscal del IVA de las compras.
- La comisión del medio de pago se aplica sobre el monto pagado por el cliente.
- Si la comisión publicada no incluye IVA, primero debe calcularse la comisión efectiva (`c`).
- Si cambian la tasa de IVA o la comisión del medio de pago, basta con actualizar los valores de `i` y `c`; las fórmulas seguirán siendo válidas.