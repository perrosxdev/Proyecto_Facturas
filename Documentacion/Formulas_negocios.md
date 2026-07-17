# Cálculo de Precio de Venta

Este documento describe las fórmulas utilizadas para calcular el precio de venta de un producto considerando:

- Costo del producto.
- Ganancia neta deseada.
- IVA.
- Comisión por ventas mediante TUU.

---

# Variables

| Variable | Descripción |
|----------|-------------|
| `C` | Costo del producto |
| `Cn` | Costo neto (sin IVA) |
| `Pn` | Precio neto (sin IVA) |
| `Pf` | Precio final de venta |
| `G` | Ganancia neta deseada |
| `i` | Tasa de IVA (ej. `0.19`) |
| `t` | Comisión efectiva de TUU (ej. `0.017731`) |

---

# Comisión efectiva de TUU

La comisión efectiva corresponde a la comisión más el IVA aplicado sobre dicha comisión.

Ejemplo:

```text
Comisión TUU = 1,49%
IVA          = 19%
```

```text
t = 0.0149 × 1.19
t = 0.017731
```

---

# Opción 1: El costo NO incluye IVA

Utilice esta opción cuando el costo ingresado corresponda al valor **neto**.

## Paso 1: Calcular el precio neto

$$
Pn = C + G
$$

## Paso 2: Calcular el precio final

$$
Pf = \frac{Pn(1+i)}{1-t}
$$

### Fórmula resumida

$$
Pf = \frac{(C+G)(1+i)}{1-t}
$$

---

# Opción 2: El costo SÍ incluye IVA

Utilice esta opción cuando el costo ingresado ya incluya IVA.

## Paso 1: Obtener el costo neto

$$
Cn = \frac{C}{1+i}
$$

## Paso 2: Calcular el precio neto

$$
Pn = Cn + G
$$

## Paso 3: Calcular el precio final

$$
Pf = \frac{Pn(1+i)}{1-t}
$$

### Fórmula resumida

$$
Pf = \frac{\left(\frac{C}{1+i}+G\right)(1+i)}{1-t}
$$

---

# ¿Por qué se divide por (1 - t)?

La comisión de TUU se descuenta del monto pagado por el cliente.

Ejemplo:

```text
Cliente paga        $100,00
Comisión TUU         $1,77
Monto recibido      $98,23
```

Lo anterior equivale a:

$$
100(1-t)
$$

Por ello, para recibir exactamente el monto esperado, el precio debe calcularse dividiendo por:

$$
1-t
$$

---

# Valores utilizados actualmente

| Concepto | Valor |
|----------|------:|
| IVA | 19% |
| Comisión TUU | 1,49% |
| Comisión efectiva TUU | 1,7731% |
| `i` | 0.19 |
| `t` | 0.017731 |

---

# Ejemplo

Datos:

```text
Costo con IVA (C) = $27.205
Ganancia (G)      = $7.000
```

### 1. Obtener costo neto

$$
Cn=\frac{27.205}{1.19}=22.861
$$

### 2. Obtener precio neto

$$
Pn=22.861+7.000=29.861
$$

### 3. Obtener precio final

$$
Pf=\frac{29.861(1.19)}{1-0.017731}
=36.176
$$

**Precio recomendado:** **$36.176**

---

# Resumen

## Si el costo NO incluye IVA

$$
Pf=\frac{(C+G)(1+i)}{1-t}
$$

## Si el costo SÍ incluye IVA

$$
Pf=\frac{\left(\frac{C}{1+i}+G\right)(1+i)}{1-t}
$$