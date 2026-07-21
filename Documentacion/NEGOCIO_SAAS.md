# NEGOCIO_SAAS.md — Modelo de Negocio, Planes y Comercialización · Thoth

> Este documento define **cómo Thoth se convierte en un negocio**, no solo en un producto.
> Complementa a `LOGICA_NEGOCIO.md` (qué calcula el sistema para el cliente) y a
> `OPTIMIZACION.md` (su capacidad más avanzada) con la pregunta que ninguno de los dos
> responde: **¿cómo se vende, se cobra, y se sostiene Thoth como negocio propio?**

**Estado del documento:** define lo justo y necesario para partir. Los montos y políticas
aquí son un punto de partida razonable basado en el mercado chileno actual, no un contrato
grabado en piedra — se ajustan con datos reales apenas existan clientes pagando.

---

## Índice

1. [Estado Actual y Cronología](#1-estado-actual-y-cronología)
2. [Modelo de Planes y Precios](#2-modelo-de-planes-y-precios)
3. [Medios de Pago y Cobro a Clientes](#3-medios-de-pago-y-cobro-a-clientes)
4. [Estructura Legal y Facturación](#4-estructura-legal-y-facturación)
5. [Mercado Objetivo y Segmentación](#5-mercado-objetivo-y-segmentación)
6. [Estrategia de Adquisición de Clientes](#6-estrategia-de-adquisición-de-clientes)
7. [Onboarding de Clientes Nuevos](#7-onboarding-de-clientes-nuevos)
8. [Soporte al Cliente y Disponibilidad](#8-soporte-al-cliente-y-disponibilidad)
9. [Métricas de Negocio a Trackear](#9-métricas-de-negocio-a-trackear)
10. [Roadmap Comercial](#10-roadmap-comercial)
11. [Pendientes Legales](#11-pendientes-legales)

---

## 1. Estado Actual y Cronología

Hoy Thoth **no se vende** — está en fase de documentación y desarrollo, validándose
internamente con la distribuidora de huevos familiar. Este documento define el modelo para
cuando ese momento llegue, pero una decisión de fondo ya está tomada:

> **Thoth no se distribuye a clientes externos ni se cobra por su uso hasta que la empresa
> esté formalmente constituida** (SpA u otra estructura, con inicio de actividades ante el
> SII). No tiene sentido resolver medios de pago o facturación antes de eso — ver
> secciones 3 y 4.

Esto significa que el orden lógico es: (1) validar el producto con el caso interno, (2)
formalizar la empresa, (3) recién ahí abrir la venta a los primeros clientes externos con
pago real.

---

## 2. Modelo de Planes y Precios

### 2.1 Filosofía general — modular, no por rubro

La primera versión de este documento proponía planes fijos ("Starter", "Pro" con todo
incluido). Se descarta ese enfoque a favor de un **modelo modular**, por una razón de
fondo que conecta directo con cómo está diseñado el resto del producto: `LOGICA_NEGOCIO.md`
y `OPTIMIZACION.md` son deliberadamente genéricos, sin nada hardcodeado a un rubro — un
sistema de precios rígido por rubro ("Plan Distribuidora", "Plan Restaurant") iría en
contra de ese principio y además no refleja la realidad: **un restaurant con varias
sucursales pequeñas necesita más bodegas/sucursales pero no necesariamente Flota, mientras
que un minimarket de un solo local no necesita ninguna de las dos.**

La solución: **un plan base según tamaño de operación** (usuarios, productos, bodegas) +
**módulos opcionales** que cualquier cliente activa o no según lo que realmente necesita,
sin importar su rubro. El "rubro" del cliente no restringe nada — solo se usa como
**sugerencia en el onboarding** (sección 7.1) para recomendar qué módulos activar primero.

Como referencia de mercado (sin copiar su estructura): Bsale cobra entre 1,5 y 2,9 UF +
IVA al mes (~$70.000–$135.000 CLP) por un POS/ERP multi-sucursal; GranLoop, más enfocado a
inventario con IA para minimarkets, cobra entre $9.990 y $40.000 CLP al mes. El modelo de
Thoth se posiciona en ese mismo rango, pero de forma modular en vez de por escalones fijos.

### 2.2 Plan base — según tamaño de operación

El plan base incluye siempre el núcleo operacional: productos, bodegas/sucursales,
inventario, clientes, ventas y compras. Lo que cambia entre Starter y Pro son los límites
de tamaño, no las funciones incluidas:

| Plan base | Precio mensual (CLP + IVA) | Usuarios | Productos | Bodegas/Sucursales |
|---|---|---|---|---|
| **Demo** | Gratis, sin límite de tiempo | 1 | 15 | 1 |
| **Starter** | $15.990 | 5 | 300 | 2 |
| **Pro** | $21.990 | 20 | 2.000 | 8 |

El Demo se mantiene igual que en la versión anterior de este documento — permanente, no
por tiempo limitado (ver justificación en sección 2.3 más abajo, sin cambios).

### 2.3 Módulos opcionales (add-ons)

Se activan sobre cualquier plan base, Starter o Pro, según lo que el negocio realmente
necesite:

| Módulo | Precio mensual adicional | Para quién tiene sentido | Prerrequisito |
|---|---|---|---|
| **Flota** (vehículos, rutas, mantenimientos) | $9.990 | Cualquier negocio con reparto o despacho propio — no exclusivo de distribuidoras | — |
| **Analytics** (dashboards, KPIs, predicciones Prophet) | $12.990 | Cualquier negocio que quiera visibilidad de su operación con datos reales | — |
| **Optimización** (incluye Analytics y agrega Programacion lineal y no lineal, ver `OPTIMIZACION.md`) | $19.990 | Negocios con decisiones de compra o precio complejas (múltiples productos, presupuesto/bodega limitados) | La optimización se apoya en costos, márgenes y demanda que Analytics ya debe estar calculando (ver `OPTIMIZACION.md` sección 13.8) |

**Por qué Flota es opcional para todos y no exclusivo de un rubro:** un restaurant o
minimarket con reparto propio (delivery) lo puede necesitar tanto como una distribuidora;
una distribuidora que solo vende para retiro en bodega, no. Restringirlo por rubro sería
una regla de negocio arbitraria que el producto no necesita imponer.

### 2.4 Add-on de capacidad — sucursales/bodegas adicionales

Pensado específicamente para el caso de un restaurant o minimarket con **varias sucursales
pequeñas** que no necesita más usuarios ni más productos, solo más puntos:

| Add-on | Precio mensual | Qué agrega |
|---|---|---|
| Paquete +5 bodegas/sucursales + 10 Usuarios | $9.990 | 5 bodegas/sucursales adicionales al límite del plan base contratado |
| Paquete +5 usuarios | $4.990 | 5 usuarios adicionales al límite del plan base contratado |
| Paquete +10 usuarios | $6.990 | usuarios adicionales al límite del plan base contratado |

Esto evita forzar a un cliente a saltar de Starter a Pro completo (con todos sus límites
más altos de usuarios y productos, que quizás no necesita) solo para conseguir más
sucursales. (ajustar segun el posible consumo que podrian generar en el servidor)

### 2.5 Ejemplos aplicados — mismo motor, distinta combinación

| Negocio | Combinación | Costo mensual |
|---|---|---|
| Distribuidora de huevos (1-2 bodegas, reparto propio) | Starter + Flota | $19.990 + $9.990 = **$29.980** |
| Restaurant con 6 locales pequeños, sin reparto propio | Starter + 1 paquete de sucursales | $19.990 + $6.990 = **$26.980** |
| Minimarket de un solo local | Starter solo | **$19.990** |
| Distribuidora en crecimiento que quiere optimizar compras | Pro + Flota + Analytics + Optimización | $29.990 + $9.990 + $12.990 + $14.990 = **$67.960** |

Ningún rubro está obligado a pagar por módulos que no usa — el mismo motor de Thoth sirve
para los cuatro casos sin ninguna diferencia de código.
(ajustar ejemplos a nueva tabla add-on)

### 2.6 Descuentos por ciclo de pago

Se aplican sobre el **total mensual** de la combinación elegida (base + módulos + add-ons
de capacidad), no sobre cada componente por separado:

| Ciclo | Descuento |
|---|---|
| Mensual | — |
| Semestral | -10% sobre el total, cobrado cada 6 meses |
| Anual | -20% sobre el total, cobrado una vez al año |

**Ejemplo aplicado** (caso de la distribuidora de huevos, Starter + Flota = $29.980/mes):

```
Mensual:    $29.980 / mes
Semestral:  $29.980 × 0.9 = $26.982/mes → $161.892 cada 6 meses
Anual:      $29.980 × 0.8 = $23.984/mes → $287.808 al año
```

### 2.7 Sobre un futuro plan "Enterprise"

No existe un plan Enterprise activo hoy. Con el modelo modular esto importa menos que
antes — un cliente grande simplemente combina Pro + todos los módulos + varios paquetes de
sucursales, y ya está pagando un monto proporcional a su tamaño real sin necesitar un plan
especial. Si en el futuro aparece un caso que realmente no calza (ej. más de 20 usuarios o
más de 5.000 productos), se resuelve como **cotización personalizada caso a caso**, no
como un plan publicado en la web.

### 2.8 Nota técnica — cómo se implementa

Extiende el mismo patrón ya definido en `BUENAS_PRACTICAS.md` sección 19
(`tenants.limites` como JSONB), agregando qué módulos están activos:

```json
{
  "plan_base": "starter",
  "max_usuarios": 5,
  "max_productos": 500,
  "max_bodegas": 2,
  "bodegas_adicionales_compradas": 5,
  "modulos_activos": ["flota"]
}
```

El middleware de permisos (`MODULOS.md`, `BUENAS_PRACTICAS.md`) valida contra este campo
antes de permitir acceso a rutas de Flota/Analytics/Optimización — si el módulo no está en
`modulos_activos`, la funcionalidad no se muestra ni es accesible por API, sin importar el
rol del usuario.

---

## 3. Medios de Pago y Cobro a Clientes

### 3.1 Prerrequisito — empresa formalizada

Como se estableció en la sección 1, **no se implementa ningún medio de pago hasta que la
empresa esté formalmente constituida con inicio de actividades**. Esto no es solo una
preferencia de orden — es un requisito real: afiliarse a Webpay Plus (Transbank) exige un
RUT de empresa y una cuenta corriente comercial, no una cuenta de persona natural.

### 3.2 Medio de pago propuesto una vez formalizada la empresa

**Webpay Plus / Webpay Suscripciones (Transbank)** para cobro recurrente automático de las
mensualidades. Es el medio de pago más reconocido y confiable para un cliente pyme chileno
— no genera fricción ni desconfianza al momento de pagar, algo importante cuando se vende
a un dueño de negocio, no a un desarrollador.

**Alternativa a evaluar en el momento:** **Flow.cl**, un agregador de pagos chileno que
permite cobrar con Webpay sin necesidad de una afiliación directa y más compleja con
Transbank — cobra una comisión por transacción en vez de exigir un proceso de afiliación
largo. Puede ser el camino más simple para los primeros meses después de formalizar la
empresa, con la opción de migrar a una afiliación directa con Transbank más adelante si el
volumen de clientes lo justifica (menor comisión por transacción a mayor volumen).

**Nota sobre facturación de combinaciones modulares:** el cobro recurrente debe soportar
montos variables por tenant (cada cliente paga una combinación distinta de base + módulos),
no un monto fijo único como en un modelo de planes cerrados — esto es una consideración
técnica a validar con el proveedor de pago elegido antes de integrarlo.

### 3.3 Qué NO se define todavía

No se necesita resolver ahora: pasarelas internacionales, múltiples monedas, ni
facturación recurrente compleja (proration al activar un módulo a mitad de ciclo, etc.) —
eso se diseña cuando exista una base de clientes real que lo requiera. Para partir, activar
o desactivar un módulo puede tomar efecto simplemente en el ciclo de facturación siguiente,
sin prorateo.

---

## 4. Estructura Legal y Facturación

### 4.1 Estado actual vs. futuro

| | Estado actual | Estado futuro (antes de vender) |
|---|---|---|
| Estructura | No existe empresa formal | SpA (u otra estructura a definir) |
| SII | Sin inicio de actividades | Inicio de actividades como empresa |
| Facturación a clientes | No aplica — no hay clientes pagando | Boletas/facturas emitidas formalmente a cada tenant que paga |
| Medios de pago | No aplica | Webpay Plus / Flow (ver sección 3) |

### 4.2 Por qué se necesita inicio de actividades

Dos razones distintas, que conviene no confundir:

1. **Para cobrarle a tus propios clientes por usar Thoth** (este documento) — necesitas
   emitir boletas/facturas por el servicio SaaS que vendes, lo cual exige inicio de
   actividades como cualquier negocio formal en Chile.
2. **Para que Thoth emita documentos tributarios en nombre de tus clientes** (Fase 5 del
   `ROADMAP.md`, integración SII) — esa es una funcionalidad del producto que depende de
   que *cada tenant* (tu cliente) tenga su propio inicio de actividades y certificado
   digital, no del tuyo. Son dos necesidades de "inicio de actividades" completamente
   independientes — la primera es tuya como dueño del negocio Thoth, la segunda es de cada
   cliente que use el módulo SII.

---

## 5. Mercado Objetivo y Segmentación

### 5.1 Perfil de cliente ideal (ICP)

- Negocios pequeños con **1–2 puntos de operación** en su forma más simple (el caso que
  mejor calza con el plan Starter sin módulos)
- Cualquier rubro — el sistema no está limitado a distribución, aunque ese sea el caso de
  validación inicial
- Negocios que hoy gestionan inventario, ventas y/o sucursales con Excel, cuadernos, o
  sistemas genéricos que no calzan con su operación real

### 5.2 Rubros contemplados explícitamente

El "rubro" no cambia el precio ni restringe funciones (sección 2.1) — se usa como categoría
de segmentación comercial y como base para sugerir módulos en el onboarding (sección 7.1):

| Rubro | Necesidad típica | Módulos que probablemente le sirven |
|---|---|---|
| **Distribuidora** | Inventario multi-bodega, reparto propio, compras a proveedores | Flota, Analytics |
| **Restaurant** | Control de insumos y costos, posiblemente varias sucursales pequeñas | Paquete de sucursales, Analytics |
| **Minimarket** | Inventario y ventas simples, generalmente un solo local | Plan base solo, a veces Analytics |
| **Otro rubro** | Categoría abierta — cualquier negocio que necesite inventario + ventas + compras | Depende del caso, se define en el onboarding |

Esta tabla es una guía de venta y de UX, no una restricción técnica — un minimarket que
quiera Optimización puede activarla igual que una distribuidora.

### 5.3 Referencia rápida de posicionamiento de mercado

| Competidor | Enfoque | Precio referencial |
|---|---|---|
| Bsale | POS/ERP multi-sucursal, fuerte en boleta/factura electrónica | 1,5–2,9 UF + IVA/mes (~$70.000–$135.000 CLP) |
| GranLoop | Inventario con IA para minimarkets/almacenes/botillerías | $9.990–$40.000 CLP/mes |
| **Thoth** | ERP modular — cada negocio arma su combinación (base + módulos) | $19.990–$68.000 CLP/mes aprox., según combinación |

No es una comparación exhaustiva — solo la referencia mínima para justificar que el
posicionamiento de precio de Thoth es razonable frente a lo que ya existe en el mercado
chileno.

---

## 6. Estrategia de Adquisición de Clientes

### 6.1 Fase 1 — Venta directa (arranque)

Los primeros clientes fuera de la distribuidora de huevos se consiguen por **venta
directa**, aprovechando la red de contactos que ya existe dentro del rubro de distribución
(proveedores, otros distribuidores conocidos, clientes de la distribuidora). Es el canal
de menor costo y mayor tasa de conversión al principio, porque hay confianza previa.

### 6.2 Fase 2 — Redes sociales y contenido

En paralelo o después de los primeros clientes directos, sumar presencia en redes sociales
orientada a dueños de pyme (no a desarrolladores) — casos de uso reales, antes/después de
usar el sistema, contenido educativo simple (ej. "cómo saber si estás vendiendo bajo el
costo", conectado directamente a `LOGICA_NEGOCIO.md`). El modelo modular además da un
ángulo de venta natural: "paga solo por lo que tu negocio realmente usa".

### 6.3 Principio de autoservicio

La estrategia de crecimiento asume que **el producto debe venderse y configurarse solo**,
sin depender de que alguien lo instale personalmente en cada cliente nuevo. Esto es
obligatorio, no opcional, porque el soporte inicial es una sola persona (sección 8) — un
modelo que dependa de instalación asistida no escala más allá de un puñado de clientes.
Esto refuerza el principio de diseño ya declarado en `README.md` ("la aplicación debe ser
completamente intuitiva"). El modelo modular no debe complicar esto: activar/desactivar un
módulo debe ser un simple toggle en la configuración del tenant, no un proceso manual.

---

## 7. Onboarding de Clientes Nuevos

### 7.1 Flujo autoservicio propuesto

```
1. Cliente se registra desde la web (crea su tenant automáticamente)
2. Wizard pregunta: "¿A qué se dedica tu negocio?"
   → Distribuidora / Restaurant / Minimarket / Otro
3. Según la respuesta, Thoth sugiere (no obliga) los módulos de la tabla 5.2
   ej: "Como tienes reparto propio, ¿quieres activar el módulo Flota?"
4. Cliente confirma su combinación (puede ignorar la sugerencia)
5. Elige plan base (Demo por defecto, puede subir a Starter/Pro cuando quiera)
6. Wizard inicial: nombre de la empresa, primera bodega, primeros productos
7. Tutoriales en video enlazados directamente en cada pantalla clave
8. Cliente opera solo — soporte por correo si algo no queda claro
```

### 7.2 Tutoriales en video

Complemento directo del principio de autoservicio — cubrir primero los flujos más
frecuentes y de mayor fricción potencial:

1. Cargar el catálogo de productos inicial
2. Registrar el stock inicial por bodega
3. Crear y confirmar el primer pedido
4. Registrar una compra y recibir mercadería
5. Activar y usar un módulo opcional (Flota o Analytics) una vez contratado
6. Leer el dashboard principal (una vez el cliente tenga Analytics activo)

### 7.3 Migración de datos desde otro sistema

Cuando lleguen clientes que ya operan con Excel u otro sistema, van a necesitar importar
su catálogo, clientes e inventario existente — hoy Thoth no tiene ese flujo definido. Este
documento solo lo deja señalado como un requisito pendiente; el diseño detallado (formato
de importación, validaciones, mapeo de columnas) se documenta aparte cuando se vuelva
bloqueante para un cliente real.

---

## 8. Soporte al Cliente y Disponibilidad

### 8.1 Canal formal

Correo dedicado (ej. `soporte@thoth.cl` o dominio que se defina) como canal único y
formal desde el día uno de venta a clientes externos — aunque hoy sea una sola persona
respondiéndolo, tener un canal con nombre propio (no un Gmail personal) da una imagen más
seria y es más fácil de escalar a un ticketing real más adelante sin cambiar la dirección
de contacto que ya conocen los clientes.

### 8.2 Expectativas realistas

Mientras el soporte sea una sola persona, el compromiso razonable es **responder dentro de
1 día hábil**, sin prometer soporte 24/7 ni tiempos de respuesta agresivos que no se
puedan sostener. Es preferible ser honesto sobre esta limitación desde el principio que
prometer algo y fallarlo.

### 8.3 Disponibilidad del servicio (sin SLA formal)

Un **SLA (Service Level Agreement)** es un compromiso contractual de disponibilidad —
ej. "99,5% del tiempo arriba, o te compensamos". Con un solo servidor físico y un solo
operador, comprometerse a un SLA formal sería una promesa que no se puede garantizar de
forma realista. La decisión para esta etapa es:

> **No ofrecer un SLA formal todavía.** En su lugar, comunicar que el sistema se monitorea
> activamente (ver `SERVIDOR.md` / `BUENAS_PRACTICAS.md` sección 20 — Prometheus, Grafana,
> alertas), sin comprometerse a un número contractual de uptime. Revisar esta decisión
> cuando exista una base de clientes que dependa de Thoth de forma crítica para operar
> — ahí sí se vuelve necesario un SLA real, respaldado por infraestructura redundante.

---

## 9. Métricas de Negocio a Trackear

Lo mínimo necesario para saber si el negocio funciona, sin sobre-instrumentar antes de
tener datos reales que trackear:

```math
MRR = \sum (\text{precio mensual efectivo de cada tenant activo})
```

> `precio mensual efectivo` ya normaliza los ciclos semestral/anual a su equivalente
> mensual (sección 2.6), y suma la combinación completa de cada tenant (base + módulos +
> add-ons de capacidad) — así el MRR es comparable sin importar cómo pagó o qué combinación
> eligió cada cliente.

```math
\text{Tasa de churn mensual} = \frac{\text{tenants que cancelaron en el mes}}{\text{tenants activos al inicio del mes}} \times 100
```

```math
ARPU = \frac{MRR}{\text{tenants activos}}
```

**Métricas a revisar mensualmente una vez haya clientes pagando:**

| Métrica | Qué mide | Por qué importa |
|---|---|---|
| MRR | Ingreso recurrente mensual | El número base de salud del negocio |
| Tenants activos | Clientes pagando (Starter + Pro, con o sin módulos) | Crecimiento real, no solo demos registradas |
| Tasa de churn | % que cancela cada mes | Si el producto retiene o no |
| Demos → clientes pagos | % de conversión | Si el plan Demo está calibrado correctamente |
| ARPU | Ingreso promedio por cliente | Si vale la pena invertir en adquisición |
| Módulos activos por tenant (promedio) | Cuántos add-ons contrata un cliente típico | Indica si el modelo modular está generando upsell real, o si nadie sale del plan base |

No se agregan métricas más avanzadas (CAC, LTV de cliente del propio negocio SaaS, cohortes)
hasta tener suficientes clientes reales para que esos números signifiquen algo — con menos
de 10-15 clientes, ese nivel de análisis es ruido, no señal.

---

## 10. Roadmap Comercial

Conecta las decisiones de este documento con las fases técnicas de `ROADMAP.md`:

| Hito comercial | Depende de |
|---|---|
| Validación interna (distribuidora de huevos) | Fase 1–2 técnicas (Core + Operaciones) — en curso |
| Formalización de la empresa | Decisión de negocio, independiente del código |
| Apertura de venta a clientes externos (Starter/Pro + módulos) | Empresa formalizada + Fase 1–3 técnicas estables |
| Habilitar Webpay/Flow con soporte de montos variables por combinación | Empresa formalizada (sección 3) |
| Módulo Optimización disponible como add-on real | Fase 6 técnica completa (`OPTIMIZACION.md`) |
| Reconsiderar plan Enterprise | Cuando aparezca demanda real por límites mayores (sección 2.7) |

---

## 11. Pendientes Legales

Explícitamente fuera del alcance de este documento — se resuelven con asesoría legal
antes de abrir la venta a clientes externos, no se redactan aquí para evitar exponerse a
errores legales por documentación informal:

- [ ] Términos de Servicio
- [ ] Política de Privacidad (especialmente relevante por manejar datos financieros y
      tributarios de terceros)
- [ ] Contrato de prestación de servicio SaaS (SLA si se decide ofrecer uno más adelante,
      condiciones de cancelación, manejo de datos al término del contrato)
- [ ] Estructura societaria definitiva (SpA vs. otra alternativa) — con un contador o
      abogado, no solo con este documento

---

*Ver [README.md](./README.md) para la visión general del producto.*
*Ver [ROADMAP.md](./ROADMAP.md) para las fases técnicas que este documento asume como
prerrequisito.*
*Ver [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md) y [OPTIMIZACION.md](./OPTIMIZACION.md) para
las capacidades del producto que sustentan los módulos opcionales.*
*Ver [BUENAS_PRACTICAS.md](./BUENAS_PRACTICAS.md) sección 19 para los límites técnicos
(`tenants.limites`) que implementan el modelo modular de la sección 2.*
