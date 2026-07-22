# DISENO.md — Diagramas Técnicos y Diseño UI/UX · Fase Pre-Desarrollo

> Este documento es una **guía de qué crear, con qué herramienta, y en qué orden** —
> no contiene los diagramas ni los wireframes en sí (esos se construyen en draw.io,
> Mermaid, Excalidraw y Penpot, según corresponda). El objetivo es evitar diseñar
> pantallas mientras se programa, y evitar tomar decisiones de arquitectura visual
> sobre la marcha — ambas cosas generan retrabajo cuando se descubren tarde.

**Por qué esta fase existe:** todos los documentos técnicos de Thoth (`ARQUITECTURA.md`,
`BASE_DE_DATOS.md`, `MODULOS.md`, `API.md`) ya definen *qué* construir y *por qué*, pero
en texto y tablas — no en algo que se pueda mirar de un vistazo para explicarle el
proyecto a alguien más, o para no perderse al programar un flujo con varios pasos. Esta
fase convierte esos documentos en material visual, **antes** de escribir la primera
línea de código de UI o de un flujo complejo.

---

## Índice

1. [Diagramas Técnicos](#1-diagramas-técnicos)
2. [Diseño UI/UX](#2-diseño-uiux)
3. [Orden de Trabajo Recomendado](#3-orden-de-trabajo-recomendado)
4. [Dónde se Guardan estos Artefactos](#4-dónde-se-guardan-estos-artefactos)
5. [Preguntas Clave que esta Fase Debe Responder](#5-preguntas-clave-que-esta-fase-debe-responder)

---

## 1. Diagramas Técnicos

### 1.1 Herramientas y cuándo usar cada una

| Herramienta | Cuándo usarla | Por qué |
|---|---|---|
| **Mermaid** | Diagramas que van a vivir en el repo (ERD, flujos, secuencia) | Es texto — se versiona con Git, se revisa en un PR como código, se renderiza directo en GitHub/GitLab sin exportar imágenes |
| **draw.io** | Diagramas más libres o con mucho detalle visual (arquitectura de infraestructura, diagramas de red) | Más control de layout que Mermaid, exporta a PNG/SVG para documentación o presentaciones |
| **Excalidraw** | Bocetos rápidos, lluvia de ideas, explicar un flujo en 5 minutos | Lo más rápido de los tres — no busca precisión, busca velocidad para pensar en voz alta |

**Regla práctica:** si el diagrama va a necesitar actualizarse cada vez que cambie el
código (ej. el ERD cuando se agregue una tabla), usar Mermaid. Si es un diagrama que se
hace una vez y rara vez cambia (ej. topología del servidor), draw.io está bien.

### 1.2 Diagramas a crear, en orden de prioridad

| # | Diagrama | Fuente (de dónde sale el contenido) | Herramienta |
|---|---|---|---|
| 1 | **Arquitectura de componentes** | El ASCII de `ARQUITECTURA.md` (sección "Diagrama de Componentes Completo") — pasar a un diagrama visual real | Mermaid o draw.io |
| 2 | **Entidad-Relación (ERD) de la base de datos** | Todas las tablas de `BASE_DE_DATOS.md` — relaciones vía `REFERENCES`, incluyendo `tenant_id` en cada una para que se vea el patrón RLS | Mermaid (`erDiagram`) |
| 3 | **Flujo del pedido** (borrador → confirmado → en_preparación → en_reparto → entregado) | `MODULOS.md` Módulo 3, con las reglas de negocio de cada transición | Mermaid (`flowchart` o `stateDiagram`) |
| 4 | **Flujo de autenticación** (login, access token, refresh token, blacklist) | `API.md` sección 2 | Mermaid (`sequenceDiagram`) |
| 5 | **Secuencia de "confirmar pedido"** (validación de stock, transacción atómica, descuento de inventario) | `BUENAS_PRACTICAS.md` sección 11 (transacciones atómicas) | Mermaid (`sequenceDiagram`) — es el flujo más crítico del sistema, vale la pena verlo paso a paso |
| 6 | **Topología de infraestructura/despliegue** (servidor, contenedores Docker, Nginx, puertos) | `SERVIDOR.md` + `ARQUITECTURA.md` sección 6 | draw.io |
| 7 | **Flujo de recepción de compra** (orden → recepción parcial/total → actualización de PMP) | `MODULOS.md` Módulo 4 + `LOGICA_NEGOCIO.md` sección 4.3 | Mermaid (`flowchart`) |

Los primeros dos (arquitectura + ERD) son los más importantes — son los que más se
consultan y los que más ayudan a explicarle el proyecto a alguien nuevo (un futuro
desarrollador, un socio, o incluso para tu propia referencia en 6 meses).

### 1.3 Qué NO diagramar todavía

No vale la pena invertir tiempo en diagramas de módulos que aún pueden cambiar de forma
significativa — por ejemplo, el módulo de Optimización (Fase 6) o la jerarquía
Sucursal→Bodegas (pendiente técnico de `NEGOCIO_SAAS.md`). Diagramar algo que todavía no
está firme en el diseño es trabajo que probablemente se repite.

---

## 2. Diseño UI/UX

### 2.1 Antes de diseñar pantallas — el design system

Empezar por las pantallas sueltas sin definir primero un sistema básico genera
inconsistencia (botones distintos en cada módulo, espaciados distintos, etc.) que
después cuesta corregir. Antes de la primera pantalla en Penpot:

- [ ] Paleta de colores (primario, secundario, estados: éxito/error/advertencia)
- [ ] Tipografía (familia, tamaños para títulos/cuerpo/etiquetas)
- [ ] Componentes base reutilizables: botón, input, tabla, tarjeta de KPI, badge de
      estado (ej. los estados de pedido de `MODULOS.md`), modal
- [ ] Espaciado y grilla base (para que todas las pantallas respiren igual)

Esto no necesita ser elaborado — es más importante que exista y se use consistentemente
que sea sofisticado. Ya existe un socio válido para esta capa según `ARQUITECTURA.md`:
Tailwind CSS + shadcn/ui en el stack de React, así que el design system de Penpot puede
espejar directamente los tokens de shadcn/ui en vez de inventar uno desde cero.

### 2.2 Pantallas a priorizar (mismo orden que Fase 1 del `ROADMAP.md`)

El diseño debe ir un paso adelante del desarrollo, no en paralelo exacto — diseñar la
pantalla de inventario mientras se programa login, por ejemplo:

| Orden | Pantalla | Por qué primero |
|---|---|---|
| 1 | Login | Punto de entrada, la ve todo el mundo |
| 2 | Layout principal (sidebar, header) | Todo lo demás vive dentro de este layout — definirlo bien evita rehacer las demás pantallas |
| 3 | Dashboard/inicio | Primera impresión después de loguearse |
| 4 | Listado + formulario de Productos | Módulo base del que dependen los demás |
| 5 | Listado + formulario de Inventario/Bodegas | Sigue el orden de `ROADMAP.md` Fase 1 |
| 6 | Listado + formulario de Ventas (Pedidos) | El flujo más complejo — vale la pena diseñarlo con calma |
| 7 | Listado + formulario de Clientes | Cierra el ciclo de Fase 1 |

Los módulos de Fase 2 en adelante (Compras, Flota, Empleados, Analytics) se diseñan
cuando se acerque esa fase — no hace falta tenerlos todos resueltos antes de escribir
código de Fase 1.

### 2.3 Fidelidad — bocetos primero, detalle después

Dos pasadas, no una sola:

1. **Baja fidelidad (wireframe):** cajas, texto de relleno, sin color ni tipografía
   real — el objetivo es validar el flujo y la disposición de la información, no cómo
   se ve. Rápido de cambiar si algo no funciona.
2. **Alta fidelidad:** con el design system de la sección 2.1 aplicado — recién acá se
   decide color, tipografía real, iconografía.

Saltarse la primera pasada y diseñar directo en alta fidelidad casi siempre termina en
más retrabajo, porque los cambios de flujo se sienten más caros de hacer cuando ya hay
detalle visual invertido.

### 2.4 Mobile (Flutter) es un diseño aparte, no una versión reducida

Según `ARQUITECTURA.md`, el móvil **no replica la web** — se enfoca en operaciones de
campo (bodeguero, repartidor, chofer). Por lo tanto:

- No se diseña "la versión mobile de cada pantalla web" — se diseñan directamente las
  pantallas que el móvil sí tiene: rutas asignadas, registro de entrega + firma digital,
  consulta/movimiento de inventario, notificaciones.
- El design system puede compartir paleta de colores y principios con la web, pero los
  componentes deben pensarse para uso táctil con una mano, muchas veces al aire libre o
  con guantes (contexto real de bodeguero/chofer) — botones grandes, poco texto, alto
  contraste.

### 2.5 Qué NO diseñar todavía

Mismo criterio que en diagramas técnicos (sección 1.3): no diseñar pantallas de
Optimización (Fase 6) todavía — `OPTIMIZACION.md` sección 10 ya define el criterio de
traducción a lenguaje simple que va a guiar esas pantallas, pero el diseño visual
concreto puede esperar a que el módulo esté más cerca de construirse.

---

## 3. Orden de Trabajo Recomendado

```
1. Diagrama de arquitectura de componentes       (1-2 horas)
2. Diagrama ERD de la base de datos              (2-3 horas, es el más largo de listar)
3. Diagrama de flujo del pedido                  (1 hora)
4. Diagrama de secuencia de autenticación        (1 hora)
5. Diagrama de secuencia de confirmar pedido     (1 hora)
6. Design system básico en Penpot                (2-4 horas)
7. Wireframes de baja fidelidad — Fase 1 completa (1 día aprox.)
8. Wireframes de alta fidelidad — Fase 1 completa (1-2 días aprox.)
9. Diagrama de topología de infraestructura       (1 hora, en paralelo con lo anterior)
10. Diagrama de flujo de recepción de compra      (1 hora, antes de Fase 2)
```

No es necesario terminar todo antes de escribir la primera línea de código — los
diagramas 1-5 y los wireframes de Fase 1 (pasos 6-8) sí deberían estar listos antes del
Paso 8 de `INICIO.md` (Backend API Node.js). El resto puede ir avanzando en paralelo con
el desarrollo, un paso adelante de cada fase.

---

## 4. Dónde se Guardan estos Artefactos

```
thoth/
├── docs/
│   ├── diagramas/           → exports PNG/SVG de draw.io, o .mmd de Mermaid
│   │   ├── arquitectura.mmd
│   │   ├── erd.mmd
│   │   ├── flujo-pedido.mmd
│   │   └── ...
│   └── diseno/
│       └── penpot-links.md  → enlaces a los proyectos de Penpot (no se puede versionar
│                               el diseño en sí, pero sí los links y capturas clave)
```

Los diagramas Mermaid (`.mmd`) se guardan como texto plano en el repo — eso significa
que cualquier cambio queda en el historial de Git como cualquier otro archivo de código,
y se puede revisar en un Pull Request igual que se revisa una función.

---

## 5. Preguntas Clave que esta Fase Debe Responder

- [ ] ¿Alguien nuevo en el proyecto puede entender cómo se conectan los componentes solo mirando el diagrama de arquitectura, sin leer `ARQUITECTURA.md` completo?
- [ ] ¿El ERD deja claro el patrón de `tenant_id` + RLS en cada tabla, o hay que explicarlo aparte?
- [ ] ¿Los wireframes de Fase 1 cubren los flujos completos (crear pedido → confirmar → entregar), no solo pantallas sueltas sin conexión entre ellas?
- [ ] ¿El design system está aplicado de forma consistente, o cada wireframe "inventa" su propio estilo?
- [ ] ¿Las pantallas mobile están pensadas para el contexto real de uso (bodega, camión, exterior), o son una copia reducida de la web?

---

*Ver [ARQUITECTURA.md](./ARQUITECTURA.md) para el contenido técnico que alimenta los diagramas de la sección 1.*
*Ver [BASE_DE_DATOS.md](./BASE_DE_DATOS.md) para el esquema completo que alimenta el ERD.*
*Ver [MODULOS.md](./MODULOS.md) para las reglas de negocio detrás de los flujos diagramados.*
*Ver [ROADMAP.md](./ROADMAP.md) y [INICIO.md](./INICIO.md) para dónde encaja esta fase en el orden general del proyecto.*