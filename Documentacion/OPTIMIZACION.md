# OPTIMIZACION.md — Programación Lineal y No Lineal · Thoth

> Este documento define **qué optimiza Thoth, cómo lo calcula, y sobre todo cómo se lo
> explica a un usuario que nunca ha visto una función objetivo en su vida.** Se escribe con
> el mismo criterio que `LOGICA_NEGOCIO.md`: fórmula general reutilizable para cualquier
> tenant + ejemplo aplicado al negocio de huevos como caso de validación. Nada de lo que
> se implemente aquí puede depender de un producto, rubro o cliente específico — cualquier
> distribuidora que use Thoth debe poder cargar sus propios productos, costos y límites y
> obtener resultados útiles sin escribir una sola línea de código.

**Principio rector de esta funcionalidad:** un dueño de distribuidora no necesita saber qué
es un "vértice del poliedro factible" — necesita saber **cuánto comprar, a quién, y cuánto
va a ganar**. Todo lo matemático en este documento existe para producir esa respuesta en
lenguaje simple. La sección 6 es tan importante como las fórmulas — léela con el mismo
cuidado.

---

## Índice

1. [Conceptos Fundamentales — Explicados sin Matemáticas](#1-conceptos-fundamentales--explicados-sin-matemáticas)
2. [Glosario Técnico ↔ Lenguaje Simple](#2-glosario-técnico--lenguaje-simple)
3. [Programación Lineal (LP)](#3-programación-lineal-lp) — incluye el método gráfico (3.5)
4. [Precio Sombra (Valores Duales)](#4-precio-sombra-valores-duales)
5. [Programación No Lineal (NLP)](#5-programación-no-lineal-nlp)
6. [Programación Entera / Mixta](#6-programación-entera--mixta)
7. [Cómo se le Presenta Esto al Usuario Final](#7-cómo-se-le-presenta-esto-al-usuario-final)
8. [Casos de Uso Genéricos para Cualquier Distribuidora](#8-casos-de-uso-genéricos-para-cualquier-distribuidora)
9. [Preguntas Clave que este Módulo Debe Responder](#9-preguntas-clave-que-este-módulo-debe-responder)
10. [Arquitectura Técnica](#10-arquitectura-técnica)
11. [Casos Borde y Honestidad Matemática](#11-casos-borde-y-honestidad-matemática)
12. [Ejemplo Integral Aplicado — Distribuidora de Huevos](#12-ejemplo-integral-aplicado--distribuidora-de-huevos)

---

## 1. Conceptos Fundamentales — Explicados sin Matemáticas

Antes de cualquier fórmula, esto es lo que hay que entender en palabras normales:

**"Optimizar" significa:** de todas las combinaciones posibles de decisiones que puedo
tomar, encontrar la que me da el mejor resultado posible, sin romper mis límites reales.

Piénsalo como armar un carro de supermercado con presupuesto fijo: quieres llevarte la
combinación de productos que más te sirva (más "valor"), sin gastar más de lo que tienes
en la billetera, ni llevar más de lo que caben en el carro. Eso, matemáticamente, ya es un
problema de optimización — Thoth simplemente lo hace con miles de productos y restricciones
a la vez, algo que a mano es imposible de calcular bien.

Tres piezas siempre están presentes:

| Pieza | En palabras simples | En el carro de supermercado |
|---|---|---|
| **Variables de decisión** | Las cosas que puedo elegir cuánto de cada una | Cuánto llevo de cada producto |
| **Función objetivo** | Lo que quiero lograr — maximizar algo bueno (ganancia) o minimizar algo malo (costo) | Maximizar "cuánto me sirve lo que llevo" |
| **Restricciones** | Mis límites reales que no puedo cruzar | El presupuesto, el espacio del carro |

**"Restricción de ≥" vs "restricción de ≤":** una restricción `≤` es un techo (ej. "no puedo
gastar más de $2.000.000"). Una restricción `≥` es un piso (ej. "necesito comprar al menos
500 cajas para cumplir mis pedidos de esta semana"). Ambas son igual de válidas y Thoth
soporta las dos.

**"Óptimo global" vs "óptimo local":** imagina que estás buscando el punto más alto en una
cordillera con los ojos vendados, solo sintiendo si subes o bajas. Si vas subiendo un cerro
y llegas a la cima, sientes que llegaste "arriba" — pero puede que exista un cerro mucho más
alto al otro lado del valle que nunca detectaste. Eso es un **óptimo local** (el mejor punto
cercano) versus el **óptimo global** (el mejor punto de todos, en toda la cordillera). Como
se explica en la sección 5, en algunos problemas Thoth puede garantizar matemáticamente que
encontró el cerro más alto de todos; en otros, solo puede garantizar que encontró un cerro
muy bueno, sin poder jurar que es el más alto de todos.

---

## 2. Glosario Técnico ↔ Lenguaje Simple

| Término técnico | Símbolo | Traducción para el usuario final |
|---|---|---|
| Variable de decisión | `x₁, x₂, ... xₙ` | "Cuánto de cada cosa" (ej. cuántas cajas de cada producto) |
| Función objetivo | `Z` | "Lo que quiero lograr" — se muestra como "Ganancia total" o "Costo total" |
| Coeficiente de la función objetivo | `cⱼ` | El aporte de una unidad de esa variable a la meta (ej. margen por caja) |
| Restricción | — | "Un límite que no puedo cruzar" |
| Coeficiente técnico | `aᵢⱼ` | Cuánto de un recurso limitado consume una unidad de la variable (ej. m³ de bodega que ocupa una caja) |
| Lado derecho de la restricción (RHS) | `bᵢ` | La cantidad total disponible de ese recurso (ej. m³ de bodega totales) |
| Región / conjunto factible | — | "Todas las combinaciones que sí cumplen mis límites" |
| Óptimo global | — | "La mejor combinación posible entre absolutamente todas las opciones válidas" |
| Óptimo local | — | "Una muy buena combinación, pero podría no ser la mejor de todas" |
| Precio sombra / valor dual | `yᵢ` | "Cuánto ganaría extra si tuviera una unidad más de ese recurso limitado" |
| Convexidad | — | "El problema tiene una sola cima, sin valles falsos que confundan" |
| Problema infactible | — | "No existe ninguna combinación que cumpla todos tus límites a la vez — se contradicen entre sí" |
| Problema no acotado | — | "Con las reglas que diste, la ganancia podría crecer sin límite — falta alguna restricción" |

---

## 3. Programación Lineal (LP)

### 3.1 Formulación general — Maximización

```math
\max \; Z = \sum_{j=1}^{n} c_j x_j
```

sujeto a:

```math
\sum_{j=1}^{n} a_{ij} \, x_j \; \le \; b_i \qquad \forall i = 1, \dots, m
```

```math
x_j \; \ge \; 0 \qquad \forall j
```

### 3.2 Formulación general — Minimización con restricciones `≥`

```math
\min \; Z = \sum_{j=1}^{n} c_j x_j
```

sujeto a:

```math
\sum_{j=1}^{n} a_{ij} \, x_j \; \ge \; b_i \qquad \forall i = 1, \dots, m
```

```math
x_j \; \ge \; 0 \qquad \forall j
```

> **Nota técnica:** un problema de maximización se convierte en uno de minimización (y
> viceversa) simplemente invirtiendo el signo de la función objetivo:
> `max Z = min(-Z)`. Esto permite usar un único solver para ambos casos — así lo hace
> `scipy.optimize.linprog`, que internamente siempre minimiza.

### 3.3 Método Simplex

El método Simplex resuelve el problema recorriendo los "vértices" de la región factible
(el espacio geométrico definido por todas las restricciones) — nunca revisa el interior,
porque en un problema lineal la mejor solución **siempre** está en un vértice, nunca en
medio. Se mueve de vértice en vértice, mejorando la función objetivo en cada paso, hasta
que ningún vecino es mejor — en ese punto encontró el óptimo.

**Garantía matemática importante:** como la región factible de un problema LP es siempre
convexa (sin "valles falsos"), el óptimo que encuentra Simplex **es el óptimo global**,
sin excepción. No hay riesgo de quedar atrapado en una solución "buena pero no la mejor".

**Implementación recomendada:** `scipy.optimize.linprog` con `method='highs'` (más rápido y
numéricamente más estable que el Simplex clásico) — pero puede forzarse
`method='simplex'` si se necesita el algoritmo específico por trazabilidad o fines
educativos dentro de la app. Ambos métodos garantizan el mismo óptimo global; solo cambia
la velocidad de cómputo.

### 3.4 Tipos de restricciones soportadas

| Tipo | Significado de negocio | Ejemplo |
|---|---|---|
| `≤` (techo) | No superar un recurso limitado | Presupuesto máximo, espacio de bodega, capacidad de un vehículo |
| `≥` (piso) | Cumplir un mínimo obligatorio | Demanda mínima por contrato, stock mínimo de seguridad |
| `=` (igualdad exacta) | Un valor fijo, sin margen | Producir exactamente el tamaño de lote que exige el proveedor |

Internamente, `linprog` solo acepta restricciones `≤` — una restricción `≥` se convierte
multiplicando ambos lados por `-1`:

```math
\sum a_{ij} x_j \ge b_i \quad\Longleftrightarrow\quad -\sum a_{ij} x_j \le -b_i
```

Esta conversión es transparente para el usuario — en la UI siempre elige `≥`, `≤` o `=` en
lenguaje natural, y el motor hace la transformación matemática internamente.

### 3.5 Método Gráfico

**Importante:** el método gráfico **no es el que Thoth usa para calcular** la solución —
eso siempre lo hace Simplex/HiGHS (sección 3.3), sin importar cuántas variables tenga el
problema. Su valor está en otro lado: es la mejor herramienta de **explicabilidad** que
existe para LP, porque permite *ver* la región factible y entender, con los propios ojos,
por qué la solución óptima es esa y no otra.

**Limitación que hay que respetar siempre:** el método gráfico solo funciona con **2
variables de decisión** (un eje X, un eje Y). Con 3 variables requiere un gráfico 3D — mucho
menos intuitivo — y con 4 o más es matemáticamente imposible de graficar. Por eso, Thoth
debe ofrecer esta vista **únicamente cuando el modelo del usuario tenga 2 variables** (como
máximo 3, con el gráfico 3D como caso especial opcional), y simplemente no mostrarla en el
resto de los casos — no tiene sentido forzarlo.

**Procedimiento matemático (para 2 variables `x₁`, `x₂`):**

1. Despejar cada restricción como una recta, para poder dibujarla:

```math
a_{i1} x_1 + a_{i2} x_2 = b_i \quad\Longrightarrow\quad x_2 = \frac{b_i - a_{i1} x_1}{a_{i2}}
```

2. Graficar todas las rectas junto con `x₁ ≥ 0` y `x₂ ≥ 0`. La **región factible** es el
   área donde se cumplen simultáneamente todas las restricciones (la intersección de todos
   los semiplanos válidos).

3. Identificar los **vértices** de esa región (las esquinas del polígono resultante) —
   estos son los únicos puntos candidatos a ser la solución óptima, por la misma razón
   geométrica que usa Simplex internamente (sección 3.3).

4. Evaluar la función objetivo en cada vértice y quedarse con el mejor valor:

```math
Z(x_1, x_2) = c_1 x_1 + c_2 x_2
```

5. El vértice ganador es la solución óptima — y coincide exactamente con lo que entrega el
   solver de Thoth, porque es el mismo problema resuelto por dos caminos distintos.

**Cómo se integra en el producto (conecta con la sección 7):** cuando Thoth detecta que un
modelo tiene 2 variables (o hasta 3, con vista 3D), muestra automáticamente un gráfico
interactivo junto al resultado numérico — como una "vista extra" que refuerza la confianza
en el número que ya calculó Simplex, **no como el método que se usó para calcularlo**. Con
más de 2–3 variables, esa vista simplemente no aparece; si el usuario pregunta por qué, un
tooltip simple explica: *"Este cálculo tiene demasiadas variables para mostrarse como
gráfico — pero el resultado se calculó con el mismo método matemático."*

---

## 4. Precio Sombra (Valores Duales)

### 4.1 Qué es matemáticamente

El precio sombra `yᵢ` de una restricción es cuánto cambiaría el valor óptimo de la función
objetivo si el lado derecho de esa restricción (`bᵢ`) aumentara en una unidad, manteniendo
todo lo demás igual:

```math
y_i = \frac{\partial Z^*}{\partial b_i}
```

Se obtiene directamente de la solución del solver — no requiere resolver el problema de
nuevo. En `scipy.optimize.linprog`, están disponibles en
`result.ineqlin.marginals` (para restricciones `≤`/`≥`) y `result.eqlin.marginals`
(para restricciones `=`).

### 4.2 Qué significa en palabras simples

El precio sombra responde: **"¿cuánto más ganaría si tuviera un poco más de este recurso
limitado?"**

- Si el precio sombra de "espacio de bodega" es `$450/m³`, significa que cada metro cúbico
  adicional de bodega que consigas te generaría hasta `$450` más de ganancia (dentro de un
  rango razonable — ver 4.3).
- Si el precio sombra de una restricción es `$0`, significa que **esa restricción no te
  está limitando** — tienes margen ahí y aflojarla no cambiaría nada. Es información tan
  valiosa como saber cuál sí te limita.

Esto convierte una pregunta financiera difícil ("¿me conviene arrendar más bodega?") en un
número directo y comparable contra el costo real de conseguir ese recurso.

### 4.3 Límite de validez del precio sombra

El precio sombra es válido solo dentro de un **rango de sensibilidad** — no es válido
indefinidamente. Si duplicas la bodega, el precio sombra probablemente cambia (otra
restricción empezará a limitar primero). Thoth debe mostrar el rango de validez
(`sensitivity range`) junto al precio sombra, no solo el número — `scipy` lo entrega en el
análisis de sensibilidad post-solución.

### 4.4 Ejemplo aplicado

```
Restricción activa: espacio de bodega ≤ 500 m³
Precio sombra: $450 / m³
Rango de validez: hasta 650 m³

→ "Si consigues hasta 150 m³ más de bodega, cada m³ adicional te genera
   aproximadamente $450 de ganancia extra. Más allá de eso, el cálculo cambia."
```

---

## 5. Programación No Lineal (NLP)

### 5.1 Cuándo un problema deja de ser lineal

Un problema es no lineal cuando la función objetivo o alguna restricción involucra
productos de variables, potencias, raíces, exponenciales, logaritmos, etc. — no se puede
escribir como una simple suma ponderada. El caso más común en un negocio de distribución:
**el precio afecta la demanda, y la demanda multiplicada por el precio da el ingreso** —
eso ya es un producto de dos cantidades que dependen la una de la otra, no una suma lineal.

```math
\text{ingreso}(p) = p \times D(p)
```

Si `D(p)` (la demanda en función del precio) no es lineal —lo normal en la vida real—
entonces `ingreso(p)` tampoco lo es, y el problema de "encontrar el precio que maximiza el
ingreso" es un problema de programación no lineal.

### 5.2 Convexidad — por qué es la pregunta más importante

**Si el problema es convexo** (una sola "cima" sin valles falsos, matemáticamente: la
función objetivo es cóncava para maximizar / convexa para minimizar, y la región factible es
convexa), entonces los métodos de gradiente encuentran el **óptimo global garantizado**,
igual que Simplex en LP.

**Si el problema es no convexo** (múltiples cimas y valles, lo más común en curvas de
demanda reales, mezclas con descuentos por volumen, economías de escala, etc.), **no hay
garantía matemática de encontrar la mejor de todas las cimas** con un solo intento. El
algoritmo puede quedar atrapado en un óptimo local que parece bueno pero no es el mejor.

> **Compromiso de honestidad del producto:** Thoth **nunca debe mostrar el resultado de un
> problema no convexo como "el óptimo global"** sin matices. Debe mostrarse como
> "la mejor solución encontrada" — ver sección 7.4 sobre cómo comunicar esto sin asustar
> al usuario ni sobre-prometer.

### 5.3 Métodos recomendados según el tipo de problema

| Situación | Método recomendado (scipy) | Garantiza óptimo global |
|---|---|---|
| Problema convexo, con restricciones | `minimize(method='SLSQP')` o `method='trust-constr'` | ✅ Sí |
| Problema convexo, sin restricciones o solo límites simples | `minimize(method='L-BFGS-B')` | ✅ Sí |
| Problema no convexo, se necesita explorar bien el espacio | `differential_evolution` | ❌ No, pero buena aproximación con suficientes iteraciones |
| Problema no convexo, con "trampas" (mínimos/máximos locales marcados) | `dual_annealing` | ❌ No, pero diseñado específicamente para escapar de óptimos locales |
| Problema no convexo, pocas variables, se puede permitir cómputo más lento | `basinhopping` | ❌ No, pero combina búsqueda local + saltos aleatorios |

### 5.4 Formulación general

```math
\min \; f(x)
```

sujeto a:

```math
g_i(x) \le 0 \qquad i = 1, \dots, m
```

```math
h_j(x) = 0 \qquad j = 1, \dots, p
```

Donde `f`, `gᵢ`, `hⱼ` pueden ser cualquier función matemática — no solo sumas lineales.

### 5.5 Ejemplo — precio óptimo con elasticidad de demanda

Un modelo simple y muy usado de demanda en función del precio (elasticidad constante):

```math
D(p) = D_0 \left(\frac{p}{p_0}\right)^{-e}
```

Donde `D₀` es la demanda observada a un precio de referencia `p₀`, y `e` es la elasticidad
(qué tan sensible es la demanda a cambios de precio — típicamente `e > 1` para productos
sustituibles, `e < 1` para productos de necesidad básica).

```math
\max_p \; \text{ingreso}(p) = p \times D_0 \left(\frac{p}{p_0}\right)^{-e}
```

sujeto a, por ejemplo:

```math
p \ge Pf_{\text{mínimo}} \quad\text{(ver LOGICA\_NEGOCIO.md sección 2.7 — no vender bajo el piso)}
```

```math
D(p) \le \text{stock disponible}
```

Este problema **sí es convexo** para valores de `e > 1` (la función de ingreso es cóncava
en ese rango) — así que `SLSQP` o `trust-constr` bastan y garantizan el óptimo global. Para
`e ≤ 1` puede dejar de ser cóncava y conviene validar con un método global.

---

## 6. Programación Entera / Mixta

Mención breve — no es el foco de esta primera versión, pero queda documentado porque varios
casos de uso reales de Thoth lo necesitan tarde o temprano (ver `ROADMAP.md`, módulo de
Flota).

Cuando una variable de decisión solo puede tomar valores enteros (ej. "número de camiones a
usar", no se puede usar "2.3 camiones") o binarios (ej. "¿asigno este pedido a este
vehículo? sí/no"), el problema deja de ser LP puro y se convierte en **Programación Lineal
Entera Mixta (MILP)**. `scipy.optimize.linprog` no soporta esto — se requiere:

- **Google OR-Tools** (`CP-SAT` o el solver MILP) — recomendado, gratuito, mantenido por
  Google, con buen soporte de Python
- **PuLP** — más simple de escribir, usa solvers de código abierto (CBC) por debajo

**Caso de uso concreto en Thoth:** asignación óptima de pedidos a vehículos y rutas
(`MODULOS.md` — Módulo 8, Flota) es naturalmente un problema de variables binarias
(`x_{ij} = 1` si el pedido `i` va en el vehículo `j`, `0` si no), no un problema LP continuo.

---

## 7. Cómo se le Presenta Esto al Usuario Final

Esta sección es tan importante como las fórmulas — es lo que separa una herramienta útil de
una que nadie usa porque no la entiende. Ningún término de las secciones 1–6 debe aparecer
tal cual en la interfaz.

### 7.1 Principio de traducción total

Nada de "función objetivo", "restricciones", "variables de decisión", "óptimo global",
"convexidad" en la UI. En su lugar:

| Nunca mostrar | Mostrar en su lugar |
|---|---|
| "Función objetivo: maximizar Z" | "¿Qué quieres lograr?" → botones: **Maximizar mi ganancia** / **Minimizar mi costo** |
| "Variable de decisión xⱼ" | El nombre real del producto/recurso, con un campo "¿cuánto puedes comprar como máximo de esto?" |
| "Restricción ≤ / ≥ / =" | "No puede superar…" / "Debe ser al menos…" / "Debe ser exactamente…" |
| "Región factible" | (no se muestra — es un concepto interno) |
| "Solución óptima" | "La mejor combinación encontrada" |
| "Precio sombra de la restricción i" | "Si consiguieras más de [recurso], ganarías aproximadamente $X más por cada unidad extra" |
| "Problema infactible" | "No encontramos ninguna combinación que cumpla todas tus condiciones a la vez. Revisa si alguno de tus límites es demasiado estricto." |
| "Problema no acotado" | "Con las condiciones que diste, no hay un límite claro de cuánto podrías ganar — probablemente falta indicar algún límite (ej. presupuesto o stock disponible)." |

### 7.2 Flujo de configuración (wizard, no formulario técnico)

```
Paso 1 — ¿Qué quieres lograr?
  ○ Maximizar mi ganancia
  ○ Minimizar mis costos de compra
  ○ Maximizar cuántos pedidos puedo cubrir

Paso 2 — ¿Con qué productos/recursos estás trabajando?
  (selector de productos ya existentes en el catálogo — no se pide texto libre)

Paso 3 — ¿Cuáles son tus límites?
  Por cada recurso relevante (presupuesto, bodega, vehículos, demanda mínima):
  [ Presupuesto disponible este mes ]  [ no puede superar ▾ ]  [ $______ ]
  [ Espacio de bodega disponible   ]  [ no puede superar ▾ ]  [ ______ m³ ]
  [ Demanda mínima comprometida    ]  [ debe ser al menos ▾ ]  [ ______ unid ]

Paso 4 — Resultado
  "La mejor combinación que encontramos es:
     · 320 cajas de Producto A
     · 180 cajas de Producto B
   Con esto, tu ganancia estimada es $2.450.000 este mes."

  [ Ver qué te está limitando más ]  ← despliega el precio sombra en lenguaje simple
```

### 7.3 Cómo mostrar el precio sombra sin jerga

En vez de una tabla de "valores duales", mostrar una lista ordenada de "cuellos de botella":

```
🔒 Lo que más te está limitando ahora:

1. Espacio de bodega — cada m³ adicional te daría ~$450 más de ganancia
2. Presupuesto de compra — cada $10.000 adicionales te darían ~$1.200 más de ganancia

✅ Esto NO te está limitando (tienes margen de sobra):
   · Capacidad de tus vehículos
```

### 7.4 Cómo comunicar honestamente los problemas no convexos (NLP)

Cuando el resultado viene de un método sin garantía de óptimo global (sección 5.3), la UI
debe ser transparente sin sonar insegura ni asustar al usuario con matemáticas:

```
✅ "Encontramos la mejor combinación entre las miles que probamos."

⚠️ Evitar: "Este resultado podría no ser matemáticamente óptimo con probabilidad
   no acotada según la convexidad del dominio de búsqueda."
```

Si se quiere dar más contexto a un usuario que lo pida (botón "¿cómo se calculó esto?"):

```
"Este tipo de cálculo (precio con demanda variable) es más complejo que una simple
suma — probamos muchas combinaciones distintas de forma inteligente y te mostramos
la mejor que encontramos. En la gran mayoría de los casos es la mejor posible."
```

### 7.5 Casos donde no hay solución

- **Infactible:** mostrar cuál de las restricciones probablemente está en conflicto con
  otra (ej. "pediste al menos 500 unidades pero tu presupuesto solo alcanza para 300 —
  ajusta uno de los dos"). Nunca solo decir "no se encontró solución".
- **No acotado:** guiar al usuario a agregar el límite faltante, casi siempre presupuesto o
  stock máximo disponible.

---

## 8. Casos de Uso Genéricos para Cualquier Distribuidora

Diseñados para que ningún tenant necesite personalización de código — solo cargar sus
propios productos, costos y límites.

| Caso de uso | Tipo | Variables de decisión | Función objetivo | Restricciones típicas |
|---|---|---|---|---|
| Mezcla óptima de compra | LP (max) | Cantidad a comprar de cada producto | Maximizar margen total | Presupuesto ≤, bodega ≤, demanda mínima ≥ |
| Minimizar costo de abastecimiento | LP (min) | Cantidad a comprar por proveedor/producto | Minimizar costo total | Demanda mínima ≥, capacidad por proveedor ≤ |
| Priorización de pedidos con stock limitado | LP (max) | Cuánto de cada pedido despachar | Maximizar ingresos o clientes atendidos | Stock disponible ≤, cumplimiento mínimo por cliente clave ≥ |
| Precio óptimo con elasticidad | NLP | Precio de cada producto | Maximizar ingreso o margen | Precio mínimo ≥, stock disponible ≤ |
| Asignación de vehículos a rutas | MILP | Asignación binaria pedido↔vehículo | Minimizar costo de flota o maximizar entregas | Capacidad por vehículo ≤, cada pedido asignado a exactamente un vehículo (=) |
| Plan de producción/empaque (si aplica a futuro) | LP o MILP | Unidades a producir/empacar por línea | Maximizar margen o minimizar desperdicio | Capacidad de línea ≤, insumos disponibles ≤ |

---

## 9. Preguntas Clave que este Módulo Debe Responder

- [ ] Dado mi presupuesto y mi bodega disponible, ¿qué combinación de compras me da la mayor ganancia posible?
- [ ] ¿Cuál es el costo mínimo posible para cumplir toda la demanda comprometida de este período?
- [ ] Si tengo stock limitado de un producto muy pedido, ¿cómo lo reparto entre clientes para maximizar mis ingresos sin perder a mis clientes clave?
- [ ] ¿Qué recurso (bodega, presupuesto, vehículos) es el que realmente me está limitando para ganar más — y cuánto ganaría si consiguiera un poco más de ese recurso?
- [ ] Dado que el precio afecta cuánto me compran, ¿cuál es el precio que maximiza mis ingresos totales, no solo el margen por unidad?
- [ ] ¿Cómo asigno mis vehículos a las rutas del día minimizando el costo total de reparto?
- [ ] Si mis restricciones actuales no tienen solución posible, ¿cuál de mis condiciones es la que está generando el conflicto?

---

## 10. Arquitectura Técnica

### 10.1 Ubicación en el stack

Vive en `apps/api-python/`, como un router nuevo (`routers/optimizacion.py`), siguiendo el
mismo patrón que el resto del servicio de analytics descrito en `ANALYTICS.md` y
`ARQUITECTURA.md`. No requiere cambios en `api-node` más allá de exponer el proxy hacia
Python, igual que ya existe para predicciones.

### 10.2 Librerías

```python
scipy          # linprog (LP), minimize (NLP convexo), differential_evolution / dual_annealing (NLP no convexo)
pulp           # alternativa declarativa para LP/MILP, más legible al modelar restricciones dinámicas por tenant
ortools        # para MILP — asignación de vehículos/rutas (Google OR-Tools, CP-SAT solver)
numpy          # soporte numérico
pydantic       # validación de los modelos de entrada (variables, restricciones)
```

### 10.3 Esquema de datos (propuesta, a validar contra `BASE_DE_DATOS.md`)

```sql
-- Configuración de un problema de optimización guardado por el usuario
CREATE TABLE optimizacion_modelos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    nombre          VARCHAR(255) NOT NULL,
    tipo            VARCHAR(20) NOT NULL,   -- lp | nlp | milp
    objetivo        VARCHAR(20) NOT NULL,   -- maximizar | minimizar
    configuracion   JSONB NOT NULL,         -- variables, coeficientes, restricciones (formato interno)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE optimizacion_modelos ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON optimizacion_modelos USING (tenant_id = current_tenant_id());

-- Resultados de cada corrida (para trazabilidad e historial de decisiones)
CREATE TABLE optimizacion_resultados (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id),
    modelo_id         UUID NOT NULL REFERENCES optimizacion_modelos(id),
    valor_objetivo    NUMERIC(14,2) NOT NULL,
    solucion          JSONB NOT NULL,   -- valores óptimos de cada variable
    precios_sombra    JSONB,            -- solo aplica a LP; null en NLP no convexo
    metodo_usado      VARCHAR(50) NOT NULL,  -- highs | simplex | SLSQP | differential_evolution | ...
    garantiza_global  BOOLEAN NOT NULL,      -- honestidad: true solo si el método lo garantiza
    generado_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE optimizacion_resultados ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON optimizacion_resultados USING (tenant_id = current_tenant_id());
```

> El campo `garantiza_global` existe específicamente para que el frontend sepa qué mensaje
> mostrar (sección 7.4) sin tener que reinterpretar el método usado.

### 10.4 Endpoint propuesto

```
POST /optimizacion/resolver
  Body: {
    tipo: "lp" | "nlp" | "milp",
    objetivo: "maximizar" | "minimizar",
    variables: [ { nombre, coeficiente_objetivo, limite_inferior, limite_superior } ],
    restricciones: [ { nombre, coeficientes: {...}, tipo: "<=" | ">=" | "=", valor } ]
  }
  Response: {
    valor_objetivo,
    solucion: { [variable]: valor },
    precios_sombra: { [restriccion]: valor } | null,
    metodo_usado,
    garantiza_global: boolean,
    mensaje_interpretado: string   // el texto en lenguaje simple listo para mostrar (sección 7)
  }
```

### 10.5 Fase del Roadmap sugerida

No está en las Fases 1–5 actuales de `ROADMAP.md`. Encaja naturalmente en **Fase 6 —
Escala y Expansión**, después de que Analytics (Fase 3) ya esté funcionando con datos
reales — la optimización se apoya en costos, márgenes y demanda que ya deben estar siendo
calculados correctamente por ese módulo. Se puede adelantar a un "Fase 3.5" si el negocio
lo prioriza, pero requiere que `productos.precio_costo`, `inventario` y los KPIs de
`ANALYTICS.md` ya estén sólidos, porque el motor de optimización es tan bueno como los
datos que recibe.

---

## 11. Casos Borde y Honestidad Matemática

| Caso | Qué debe hacer Thoth |
|---|---|
| Problema infactible (restricciones se contradicen) | Detectar con el propio solver (`linprog` lo reporta como `status != 0`) y sugerir cuál restricción aflojar, no solo mostrar error genérico |
| Problema no acotado (falta algún límite) | Detectar y sugerir agregar presupuesto máximo o stock disponible como restricción |
| NLP no convexo | Nunca prometer "óptimo global" — usar el lenguaje de la sección 7.4, y guardar `garantiza_global = false` en el resultado |
| Restricciones con datos desactualizados (ej. bodega ya no tiene esa capacidad) | El modelo debe poder recalcularse fácilmente — no es una configuración de "una sola vez", debe permitir volver a correr con datos frescos |
| Usuario ingresa un límite imposible (ej. presupuesto negativo) | Validar en el formulario antes de enviar al solver — nunca dejar que el solver falle silenciosamente por datos inválidos |
| Empate entre múltiples soluciones óptimas (degenerado) | Mostrar solo una (la que entrega el solver) — no es necesario explicarle al usuario que existen empates, salvo que lo pida explícitamente |

---

## 12. Ejemplo Integral Aplicado — Distribuidora de Huevos

### 12.1 Caso LP — mezcla óptima de compra

**Datos:**

```
Producto A: Huevos blancos L (caja) — margen $8.995/caja — ocupa 0,05 m³/caja
Producto B: Huevos color L (caja)   — margen $7.500/caja — ocupa 0,05 m³/caja

Presupuesto disponible este mes: $6.000.000
Costo por caja: A = $27.205, B = $24.800
Espacio de bodega disponible: 40 m³
Demanda mínima comprometida: al menos 100 cajas de A (contrato con un cliente)
```

**Formulación:**

```math
\max \; Z = 8.995\,x_A + 7.500\,x_B
```

sujeto a:

```math
27.205\,x_A + 24.800\,x_B \le 6.000.000 \quad\text{(presupuesto)}
```

```math
0.05\,x_A + 0.05\,x_B \le 40 \quad\text{(bodega)}
```

```math
x_A \ge 100 \quad\text{(demanda mínima comprometida)}
```

```math
x_A, x_B \ge 0
```

**Resultado esperado (ilustrativo):** Simplex/HiGHS entrega la combinación exacta de
`x_A` y `x_B` que maximiza el margen sin violar presupuesto, bodega ni el mínimo
comprometido — junto con el precio sombra de cada restricción, indicando si conviene
más pedir más presupuesto o más espacio de bodega el próximo mes.

> Como este modelo tiene exactamente 2 variables (`x_A`, `x_B`), es un caso ideal para
> mostrar además el gráfico interactivo de la sección 3.5 — el dueño vería visualmente
> la región factible (definida por presupuesto, bodega y el mínimo comprometido) y el
> vértice exacto donde cae la mejor combinación.

**Cómo se le muestra al dueño de la distribuidora (sección 7):**

```
"La mejor combinación es comprar 100 cajas de huevos blancos y 145 cajas de huevos
color. Con esto tu ganancia estimada este mes es $1.987.750.

🔒 Lo que más te está limitando: tu presupuesto de compra — cada $100.000
adicionales te darían aproximadamente $33.000 más de ganancia."
```

### 12.2 Caso NLP — precio óptimo con elasticidad

```
Producto: Huevos blancos L (caja)
Demanda observada (D₀): 400 cajas/semana a un precio de referencia (p₀) de $36.200
Elasticidad estimada (e): 1.4  (producto medianamente sensible al precio)
Precio mínimo permitido (piso, LOGICA_NEGOCIO.md 2.7): $33.000
Stock disponible: 500 cajas
```

```math
\max_p \; p \times 400 \left(\frac{p}{36.200}\right)^{-1.4}
```

sujeto a:

```math
p \ge 33.000
```

```math
400 \left(\frac{p}{36.200}\right)^{-1.4} \le 500
```

Como `e = 1.4 > 1`, el problema es cóncavo en el rango relevante — `SLSQP` garantiza el
óptimo global aquí. El resultado se muestra igual de simple: "El precio que maximiza tus
ingresos esta semana es $X, vendiendo aproximadamente Y cajas."

---

*Ver [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md) para las fórmulas de precio, margen e
inventario que alimentan los coeficientes de estos modelos.*
*Ver [ANALYTICS.md](./ANALYTICS.md) para el stack de Python ya definido (FastAPI, pandas,
scikit-learn) donde se integra este módulo.*
*Ver [ROADMAP.md](./ROADMAP.md) para la ubicación sugerida de esta funcionalidad en las
fases del proyecto.*
*Ver [MODULOS.md](./MODULOS.md) para las reglas de negocio existentes que estas
optimizaciones deben respetar (ej. no vender bajo el precio mínimo).*
