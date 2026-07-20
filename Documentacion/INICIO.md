# INICIO.md — Guía de Inicio Paso a Paso · Proyecto Thoth

> Este documento es el punto de entrada al proyecto.
> Sigue los pasos en orden — cada uno depende del anterior.
> Cada paso referencia el documento detallado donde encontrarás el cómo.

---

## Antes de Empezar — Leer Primero

Antes de tocar código o hardware, lee estos documentos completos. No toma más de 45 minutos y te evitará decisiones equivocadas después:

- 📄 [README.md](./README.md) — Visión general del proyecto, qué es Thoth, por qué se construye así
- 📄 [ARQUITECTURA.md](./ARQUITECTURA.md) — Stack tecnológico completo con justificaciones
- 📄 [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md) — Qué calcula Thoth y por qué (precios, márgenes, inventario, crédito)

---

## ETAPA 1 — Hardware y Servidor

> Objetivo: tener el servidor físico funcionando, accesible por SSH, listo para instalar el software.

### Paso 1 · Comprar el Hardware

Consultar la sección **Especificaciones Recomendadas** en [Servidor.md](./Servidor_Documentacion/Servidor.md).

Configuración mínima recomendada para Fase 1:

| Componente | Recomendación |
|------------|---------------|
| CPU | AMD Ryzen 7 8700G (tiene iGPU integrada — necesaria para ver el monitor) |
| Placa | MSI MAG B650 Tomahawk WiFi |
| RAM | 32 GB DDR5-5600 (2 × 16 GB, en 2 slots, dejando 2 libres) |
| Almacenamiento | 1 SSD NVMe de 1 TB (sistema + datos) + 1 SSD SATA de 1 TB (backups) |
| Fuente | 650 W 80+ Gold |
| UPS | Obligatorio — protege contra cortes de luz |

> El 8700G tiene gráficos integrados, lo que te permite conectar un monitor por HDMI
> durante la instalación sin necesidad de GPU dedicada.

---

### Paso 2 · Instalar Ubuntu Server 24.04 LTS

1. Descargar la ISO desde [ubuntu.com/download/server](https://ubuntu.com/download/server)
2. Grabar en un pendrive con **Rufus** (Windows) o **Balena Etcher** (cualquier OS)
3. Conectar al servidor: pendrive + teclado + monitor (HDMI o DP)
4. Encender y bootear desde el pendrive (F11 o F12 al encender para el menú de boot)
5. Seguir el instalador de texto:
   - Idioma: English (recomendado para compatibilidad con documentación y errores)
   - Disco: instalar en el SSD NVMe principal
   - Usuario: crear usuario no-root con contraseña segura
   - **⚠️ Marcar "Install OpenSSH Server"** — sin esto no podrás conectarte por SSH
6. Reiniciar cuando termine — desconectar el pendrive
7. Anotar la IP del servidor (se muestra al iniciar sesión por primera vez)

A partir de aquí el monitor y teclado ya no son necesarios.

---

### Paso 3 · Configurar el Servidor

Conectarse por SSH desde tu computador personal y ejecutar todos los pasos de configuración:

```bash
ssh usuario@ip-del-servidor
```

Seguir en orden los pasos del documento [Servidor.md](./Servidor_Documentacion/Servidor.md):

- [ ] Paso 1 — Actualizar el sistema
- [ ] Paso 2 — Configurar UFW (firewall)
- [ ] Paso 3 — Configurar SSH con clave pública y desactivar login por password
- [ ] Paso 4 — Configurar Fail2ban
- [ ] Paso 5 — Instalar Docker Engine
- [ ] Paso 6 — Instalar Nginx
- [ ] Paso 7 — Instalar Certbot y obtener certificado SSL
- [ ] Paso 8 — Configurar Nginx como reverse proxy
- [ ] Paso 9 — Crear estructura de directorios `/opt/thoth/`
- [ ] Paso 10 — Crear archivo `.env` con variables de entorno
- [ ] Paso 11 — Configurar backups automáticos
- [ ] Paso 12 — Instalar herramientas de monitoreo

✅ **Etapa 1 completa cuando:** puedes conectarte al servidor por SSH con clave pública, el firewall está activo y Docker responde a `docker --version`.

---

## ETAPA 2 — Configurar el Entorno de Desarrollo

> Objetivo: tener el entorno local listo para escribir y probar código antes de desplegarlo al servidor.

### Paso 4 · Configurar tu Máquina de Desarrollo

Instalar en tu computador personal:

```
Node.js 20 LTS        → runtime para el backend y las herramientas
pnpm                  → gestor de paquetes (más rápido que npm)
Python 3.12+          → para el servicio de analytics y optimización
Git                   → control de versiones
VS Code               → editor principal
Docker Desktop        → para correr PostgreSQL y Redis en local
```

Instalar extensiones de VS Code recomendadas:
```
Remote - SSH          → conectarte al servidor sin salir del editor
ESLint + Prettier     → linting y formato de código
Thunder Client        → probar la API sin salir del editor
GitLens               → historial de git dentro del editor
Dart + Flutter        → para la app móvil
```

---

### Paso 5 · Crear el Repositorio

```bash
# Crear el monorepo con la estructura definida en BUENAS_PRACTICAS.md
mkdir thoth && cd thoth
git init

# Crear estructura base de carpetas
mkdir -p apps/{web,mobile,api-node,api-python} packages/{shared-types,shared-utils} db/{migrations,seeds}

# Crear .gitignore
echo "node_modules/\n.env\ndist/\n__pycache__/\n*.pyc\n.dart_tool/" > .gitignore

# Primer commit
git add . && git commit -m "chore: estructura inicial del monorepo"
```

Subir a GitHub (repositorio privado):
```bash
git remote add origin https://github.com/tu-usuario/thoth.git
git push -u origin main
```

---

### Paso 6 · Levantar Base de Datos Local para Desarrollo

Crear `docker-compose.dev.yml` en la raíz del proyecto para desarrollo local:

```yaml
version: '3.8'
services:
  postgresql:
    image: postgres:16
    environment:
      POSTGRES_DB: thoth_dev
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_dev_data:
```

```bash
docker compose -f docker-compose.dev.yml up -d
```

---

### Paso 7 · Ejecutar las Migraciones Iniciales

Consultar [BASE_DE_DATOS.md](./BASE_DE_DATOS.md) para el esquema completo.

```bash
# Ejecutar las migraciones en orden
psql -U app_user -d thoth_dev -f db/migrations/001_init_tenants_usuarios.sql
psql -U app_user -d thoth_dev -f db/migrations/002_rls_setup.sql
psql -U app_user -d thoth_dev -f db/migrations/003_modulo_inventario.sql
# ... y así sucesivamente
```

✅ **Etapa 2 completa cuando:** puedes conectarte a PostgreSQL local, las migraciones corrieron sin error y tienes el repositorio en GitHub.

---

## ETAPA 3 — Fase 1 del Desarrollo · Core del Sistema

> Objetivo: el ciclo mínimo funcionando — inventario + ventas.
> Consultar [ROADMAP.md](./ROADMAP.md) para el detalle de tareas de cada fase.

### Paso 8 · Backend — API Node.js (Fastify)

Orden de desarrollo recomendado dentro de `apps/api-node/`:

1. **Setup base:** Fastify + TypeScript + plugins (cors, jwt, rate-limit)
2. **Autenticación:** `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout` — ver [API.md](./API.md)
3. **Middleware de tenant:** función `executeWithTenant()` que setea RLS en cada request
4. **Módulo productos:** CRUD completo con búsqueda
5. **Módulo bodegas:** CRUD + consulta de stock
6. **Módulo inventario:** movimientos, historial, alertas de stock bajo
7. **Módulo clientes:** CRUD + límite de crédito
8. **Módulo ventas (pedidos):** crear pedido, validar stock, estados, numeración automática, motor de precios (ver [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md))

> Regla: no pasar al siguiente módulo sin probar el anterior end-to-end.

---

### Paso 9 · Frontend Web — React

Orden de desarrollo recomendado dentro de `apps/web/`:

1. **Setup base:** React + Vite + TypeScript + TanStack Router + TanStack Query
2. **Login y autenticación:** pantalla de login, manejo de tokens, ruta protegida
3. **Layout principal:** sidebar de navegación, header con usuario activo
4. **Módulo inventario:** tabla de stock, formulario de movimiento, alertas
5. **Módulo ventas:** lista de pedidos, formulario de nuevo pedido, detalle de pedido
6. **Módulo clientes:** tabla y formulario

> Desarrollar web y backend en paralelo — el frontend consume la API que vas construyendo.

✅ **Fase 1 completa cuando:** puedes crear un pedido para un cliente, se descuenta el stock de la bodega, y puedes marcarlo como entregado.

---

### Paso 10 · Primer Despliegue al Servidor

Con algo funcionando en Fase 1, hacer el primer deploy real:

```bash
# En el servidor
cd /opt/thoth/app
git clone https://github.com/tu-usuario/thoth.git .

# Levantar todo con Docker Compose
docker compose up -d

# Verificar que todos los contenedores están corriendo
docker ps

# Correr migraciones en producción
docker exec -it thoth-postgresql psql -U app_user -d thoth -f /migrations/001_init.sql
```

---

## ETAPA 4 — Fase 2 · Módulos Operacionales

> Objetivo: completar el ciclo operativo completo.
> Consultar [ROADMAP.md](./ROADMAP.md) · [MODULOS.md](./MODULOS.md)

- [ ] Módulo Proveedores y Compras (órdenes de compra, recepción de mercadería)
- [ ] Módulo Empleados (roles, permisos, vinculación con usuarios)
- [ ] Módulo Flota (vehículos, rutas, asignación de conductores)

✅ **Fase 2 completa cuando:** el ciclo completo funciona — compras ingresan al inventario, pedidos salen con vehículo asignado y conductor, y se marcan como entregados.

---

## ETAPA 5 — Fase 3 · Analytics y Dashboards

> Objetivo: visibilidad completa del negocio.
> Consultar [ANALYTICS.md](./ANALYTICS.md) · [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md)

### Paso 11 · Servicio Python (FastAPI)

Dentro de `apps/api-python/`:

1. Setup FastAPI + SQLAlchemy + Pandas
2. Endpoints de KPIs por módulo (ventas, inventario, compras, flota) — fórmulas en [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md)
3. Exportación a Excel (openpyxl)
4. Dashboard principal con datos en tiempo real
5. Predicciones con Prophet (cuando haya ≥ 90 días de datos)

- [ ] Dashboard principal con KPIs
- [ ] Reportes exportables (Excel/PDF)
- [ ] Predicción de demanda
- [ ] Simulación de escenarios

✅ **Fase 3 completa cuando:** el dueño del negocio puede ver ingresos del día, productos por acabarse y una proyección de los próximos 30 días.

---

## ETAPA 6 — Fase 4 · App Móvil Android (Flutter)

> Consultar [ARQUITECTURA.md](./ARQUITECTURA.md) · sección Flutter

Dentro de `apps/mobile/`:

1. Setup Flutter + Riverpod + Dio
2. Login y manejo de tokens JWT
3. Pantalla de rutas asignadas (chofer)
4. Actualización de estado de entrega + firma digital
5. Consulta y movimiento de inventario (bodeguero)
6. Notificaciones push
7. Modo offline con Hive

✅ **Fase 4 completa cuando:** un chofer puede ver sus pedidos en el celular y registrar una entrega con firma digital.

---

## ETAPA 7 — Fase 5 · Integración SII Chile

> Solo iniciar esta etapa cuando las fases 1–4 estén estables en producción.
> Consultar [MODULOS.md](./MODULOS.md) · Módulo 8

**Prerrequisitos antes de empezar:**
- [ ] Empresa inscrita como contribuyente DTE en el SII
- [ ] Certificado digital vigente
- [ ] Decisión tomada: ¿integración directa con SII o via proveedor certificado (ACEPTA, OpenDTE)?

---

## ETAPA 8 — Fase 6 · Escala, Multi-Rubro y Optimización

> Solo iniciar cuando Analytics (Fase 3) esté sólido en producción — el módulo de
> optimización depende de costos, márgenes y predicciones ya calculados correctamente.
> Consultar [OPTIMIZACION.md](./OPTIMIZACION.md) para el diseño completo.

- [ ] Motor de optimización LP — mezcla óptima de compra, precio sombra
- [ ] Motor de optimización NLP — precio óptimo con elasticidad de demanda
- [ ] Optimización multi-período y bajo incertidumbre (conectada a Prophet)
- [ ] Comparación "dinero dejado en la mesa"
- [ ] Multi-rubro, planes diferenciados, API pública

✅ **Fase 6 completa cuando:** un dueño de distribuidora puede pedirle a Thoth una recomendación de compra o de precio y recibirla en lenguaje simple, sin necesitar conocimientos matemáticos.

---

## Resumen Visual del Orden

```
ETAPA 1 · Hardware y Servidor
    │
    ├── Paso 1 · Comprar hardware (AM5 · 8700G · B650 · 32GB DDR5)
    ├── Paso 2 · Instalar Ubuntu Server 24.04 LTS
    └── Paso 3 · Configurar servidor (Docker · Nginx · SSL · Firewall)
                │
ETAPA 2 · Entorno de Desarrollo
                │
    ├── Paso 4 · Configurar máquina local (Node · Python · VS Code)
    ├── Paso 5 · Crear repositorio Git (monorepo)
    ├── Paso 6 · Levantar BD local (Docker Compose dev)
    └── Paso 7 · Ejecutar migraciones iniciales
                │
ETAPA 3 · Fase 1 — Core
                │
    ├── Paso 8 · Backend API Node.js (auth · inventario · ventas · motor de precios)
    ├── Paso 9 · Frontend React (login · inventario · ventas)
    └── Paso 10 · Primer deploy al servidor
                │
ETAPA 4 · Fase 2 — Operaciones
                │
    └── Compras · Empleados · Flota
                │
ETAPA 5 · Fase 3 — Analytics
                │
    └── Python FastAPI · Dashboards · KPIs · Predicciones
                │
ETAPA 6 · Fase 4 — App Móvil
                │
    └── Flutter Android · Entregas · Firma digital · Offline
                │
ETAPA 7 · Fase 5 — SII Chile
                │
    └── Boletas y facturas electrónicas
                │
ETAPA 8 · Fase 6 — Escala y Optimización
                │
    └── Programación lineal/no lineal · Multi-rubro · Planes SaaS
```

---

## Documentos de Referencia

| Documento | Cuándo consultarlo |
|-----------|-------------------|
| [README.md](./README.md) | Visión general y decisiones macro |
| [ARQUITECTURA.md](./ARQUITECTURA.md) | Dudas sobre el stack tecnológico |
| [BASE_DE_DATOS.md](./BASE_DE_DATOS.md) | Esquema SQL, RLS, multitenancy |
| [MODULOS.md](./MODULOS.md) | Reglas de negocio de cada módulo |
| [API.md](./API.md) | Endpoints, autenticación, formatos |
| [ANALYTICS.md](./ANALYTICS.md) | KPIs, dashboards, predicciones |
| [ROADMAP.md](./ROADMAP.md) | Tareas detalladas por fase |
| [BUENAS_PRACTICAS.md](./BUENAS_PRACTICAS.md) | Seguridad, testing, CI/CD, convenciones |
| [LOGICA_NEGOCIO.md](./LOGICA_NEGOCIO.md) | Fórmulas de precio, margen, inventario, crédito y flota |
| [OPTIMIZACION.md](./OPTIMIZACION.md) | Programación lineal y no lineal — mezcla óptima, precio sombra, precio con elasticidad |
| [Servidor.md](./Servidor_Documentacion/Servidor.md) | Hardware, instalación y administración del servidor |

---

*Proyecto Thoth · Documentación v1.0 · Junio 2026*
