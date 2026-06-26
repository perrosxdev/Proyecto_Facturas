# Servidor.md — Montaje del Servidor Físico para Thoth

> Sistema operativo recomendado: **Ubuntu Server 24.04 LTS**
> (Debian 12 es una alternativa válida con comandos casi idénticos)

---

## Especificaciones Recomendadas de Hardware

| Componente | Fase 1 (lanzamiento) | Fase 2 (año 1, 100–200 usuarios) |
|------------|----------------------|-----------------------------------|
| CPU | 8 cores / 16 threads | 12–16 cores / 24–32 threads |
| RAM | 32 GB DDR4/DDR5 | 64 GB DDR5 |
| Almacenamiento principal | 1 TB SSD NVMe PCIe 4.0 | 2 TB SSD NVMe PCIe 4.0 |
| Disco para backups | 500 GB SSD/HDD | 1 TB SSD |
| Red | 300 Mbps simétrico | 1 Gbps simétrico |
| UPS | 1000–1500 VA | 1500–2200 VA |
| Fuente de poder | 650 W 80+ Bronze | 750 W 80+ Gold |
| Tarjeta gráfica | No necesaria | No necesaria* |

> *Solo se recomienda una GPU dedicada si se implementan modelos de IA locales, entrenamiento de modelos o procesamiento intensivo de machine learning.

---

## Procesadores Recomendados — Plataforma AMD AM5

> **¿Por qué solo AM5?**
> AM5 es la plataforma más actual de AMD y AMD ha confirmado soporte hasta al menos 2027.
> Esto significa que puedes comprar la **placa madre una sola vez** y simplemente cambiar
> el procesador al pasar de Fase 1 a Fase 2, sin tocar nada más del servidor.
> Es la decisión más inteligente económicamente para un servidor que va a crecer.

### Fase 1 (1–5 empresas, 40–50 usuarios)

| Procesador | Núcleos/Hilos | TDP | Comentarios |
|------------|--------------|-----|-------------|
| AMD Ryzen 7 7700 | 8 / 16 | 65 W | Punto de entrada ideal. Bajo consumo, excelente rendimiento para contenedores. |
| AMD Ryzen 7 7700X | 8 / 16 | 105 W | Más frecuencia que el 7700, útil si hay picos de carga frecuentes. |
| AMD Ryzen 7 9700X | 8 / 16 | 65 W | Generación Zen 5. Mejor IPC y eficiencia que el 7700X al mismo consumo. **Mejor opción Fase 1.** |

### Fase 2 (10–30 empresas, 100–200 usuarios)

| Procesador | Núcleos/Hilos | TDP | Comentarios |
|------------|--------------|-----|-------------|
| AMD Ryzen 9 7900 | 12 / 24 | 65 W | Buen salto de núcleos manteniendo bajo consumo. |
| AMD Ryzen 9 7900X | 12 / 24 | 170 W | Mayor frecuencia, pero consume más. Requiere buena refrigeración. |
| AMD Ryzen 9 9900X | 12 / 24 | 120 W | Zen 5, mejor rendimiento por vatio que el 7900X. **Mejor opción Fase 2.** |
| AMD Ryzen 9 9950X | 16 / 32 | 170 W | Para crecimiento agresivo o si se agregan modelos ML locales. |

### Ruta de Upgrade Recomendada



> Ambos procesadores usan el mismo socket AM5 y la misma placa B650.
> El upgrade de Fase 1 a Fase 2 es literalmente: apagar servidor, cambiar CPU, encender.

---

## Placas Madre Recomendadas — AMD AM5 (Chipset B650)

> Se recomienda el chipset **B650** sobre el X670 porque ofrece el mismo soporte
> de funcionalidades necesarias para un servidor a menor costo. El X670 agrega
> características orientadas a overclocking que no son relevantes en producción.

| Placa | Slots RAM | PCIe NVMe | Comentarios |
|-------|-----------|-----------|-------------|
| **MSI MAG B650 Tomahawk WiFi** | 4 × DDR5 (hasta 192 GB) | 2 × M.2 PCIe 4.0 | La más recomendada. Buena calidad de VRM para uso 24/7, amplio soporte de drivers en Linux. |
| **ASUS TUF Gaming B650-PLUS** | 4 × DDR5 (hasta 192 GB) | 2 × M.2 PCIe 4.0 | Muy buena alternativa. ASUS tiene historial sólido de estabilidad en Linux. |
| **Gigabyte B650 AORUS Elite AX** | 4 × DDR5 (hasta 192 GB) | 2 × M.2 PCIe 4.0 | Opción válida si las anteriores no están disponibles en tu región. |

**Lo que importa verificar en cualquier placa AM5 para servidor:**
- Mínimo 4 slots DDR5 (para poder ampliar RAM en el futuro sin reemplazar módulos)
- Mínimo 2 puertos M.2 NVMe (disco principal + disco de respaldo)
- VRM de calidad (la placa va a estar encendida 24/7 durante años)
- Buen soporte de Linux (evitar placas muy nuevas con drivers inestables)

---

## Memoria RAM Recomendada — DDR5 (AM5)

### Fase 1

- **32 GB (2 × 16 GB) DDR5-5600**
- Instalar en 2 de los 4 slots (modo dual channel)
- Dejar los otros 2 slots libres para la ampliación de Fase 2

### Fase 2

- Agregar **2 × 32 GB DDR5-5600** en los slots libres → total 96 GB
- O reemplazar por **4 × 32 GB** → total 128 GB si se necesita más

**Kits recomendados:**

| Kit | Capacidad | Velocidad | Comentarios |
|-----|-----------|-----------|-------------|
| Kingston Fury Beast DDR5 | 2 × 16 GB | 5600 MT/s | Buena compatibilidad con AM5, precio accesible. |
| Corsair Vengeance DDR5 | 2 × 16 GB | 5600 MT/s | Muy estable, amplio soporte en Linux. |
| G.Skill Ripjaws S5 DDR5 | 2 × 16 GB | 5600 MT/s | Excelente relación precio/calidad. |

> **Importante:** En AM5 con Ryzen 7000/9000, la velocidad nativa del controlador de memoria
> es 5600 MT/s. No vale la pena pagar más por kits de 6000+ MT/s para un servidor —
> la diferencia de rendimiento en cargas de base de datos y contenedores es insignificante.

---

## Almacenamiento Recomendado

### SSD principal

- Samsung 990 Pro
- WD Black SN850X
- Kingston KC3000
- Crucial T500

### Disco de respaldo

- SSD SATA de 1 TB.
- HDD NAS de 4 TB (opcional para almacenamiento histórico).

---

## Tarjeta Gráfica

### ¿Es necesaria?

No.

Un servidor para:

- PostgreSQL
- Redis
- Docker
- Fastify
- FastAPI
- Nginx
- Grafana
- Prometheus

no utiliza GPU.

### ¿Cuándo sí sería útil?

- Entrenamiento de modelos de IA.
- Inferencia local de modelos LLM.
- Análisis predictivo avanzado con GPU.
- Procesamiento masivo de datos.

En esos casos podrían considerarse:

- NVIDIA RTX 4060
- NVIDIA RTX 4070
- NVIDIA RTX 5070

Actualmente, para Thoth, una GPU dedicada no aporta beneficios.

---

## Fuente de Poder Recomendada

### Fase 1

- 650 W 80+ Bronze
- Corsair CX650
- Cooler Master MWE 650
- EVGA 650 BR

### Fase 2

- 750 W 80+ Gold
- Corsair RM750e
- Seasonic Focus GX-750
- MSI MAG A750GL

> Se recomienda una fuente de buena calidad debido a que el servidor funcionará 24/7.

---

## Configuración Recomendada (Producción Inicial)

| Componente | Recomendación |
|-----------|---------------|
| CPU | AMD Ryzen 7 9700X |
| Placa | MSI MAG B650 Tomahawk WiFi |
| RAM | 32 GB DDR5-5600 (2 × 16 GB, 2 slots libres) |
| SSD principal | 1 TB NVMe PCIe 4.0 |
| Disco respaldo | 1 TB SSD |
| Fuente | 650 W 80+ Bronze |
| GPU | No necesaria |
| UPS | 1500 VA |

---

## Configuración Recomendada (Escalamiento)

| Componente | Recomendación |
|-----------|---------------|
| CPU | AMD Ryzen 9 9900X |
| Placa | MSI MAG B650 Tomahawk WiFi (misma placa) |
| RAM | 96 GB DDR5-5600 (agregar 2 × 32 GB) |
| SSD principal | 2 TB NVMe |
| Disco respaldo | 1 TB SSD |
| Fuente | 750 W 80+ Gold |
| GPU | No necesaria |
| UPS | 2200 VA |

## Software que se Instalará

```
Ubuntu Server 24.04 LTS
├── Docker Engine + Docker Compose     → orquestación de contenedores
├── Nginx                              → reverse proxy y SSL
├── Certbot                            → certificados SSL automáticos (Let's Encrypt)
├── UFW                                → firewall
├── Fail2ban                           → protección contra fuerza bruta SSH
└── Contenedores Docker:
    ├── api-node                       → Fastify (backend principal)
    ├── api-python                     → FastAPI (analytics/ML)
    ├── worker-python                  → jobs de cola
    ├── postgresql                     → base de datos
    ├── redis                          → caché y colas
    └── monitoring                     → Prometheus + Grafana
```

---

## Prerequisitos Antes de Empezar

- [ ] Servidor físico con Ubuntu Server 24.04 LTS instalado
- [ ] Acceso SSH con usuario no-root (con sudo)
- [ ] IP estática o dominio apuntando al servidor
- [ ] Puerto 22 (SSH), 80 (HTTP) y 443 (HTTPS) accesibles desde internet
- [ ] UPS conectado (para proteger contra cortes de luz)

---

## Paso 1 — Actualizar el Sistema

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git ufw fail2ban unzip htop
```

---

## Paso 2 — Configurar UFW (Firewall)

```bash
# Denegar todo por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir solo lo necesario
sudo ufw allow ssh        # Puerto 22
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS

# Activar firewall
sudo ufw enable

# Verificar estado
sudo ufw status verbose
```

> **Nunca exponer** los puertos 5432 (PostgreSQL), 6379 (Redis) ni 3000/8000 (APIs) directamente a internet. Todo el tráfico externo entra por Nginx en el 443.

---

## Paso 3 — Configurar SSH Seguro

```bash
# Generar par de claves en TU máquina local (no en el servidor)
ssh-keygen -t ed25519 -C "thoth-server"

# Copiar clave pública al servidor
ssh-copy-id usuario@ip-del-servidor

# En el servidor, deshabilitar login por password
sudo nano /etc/ssh/sshd_config
```

Cambiar o agregar estas líneas en `sshd_config`:
```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
```

```bash
# Reiniciar SSH (no cierres la sesión actual hasta verificar que funciona)
sudo systemctl restart ssh

# Abrir otra terminal y verificar que puedes entrar con clave antes de cerrar la sesión actual
```

---

## Paso 4 — Configurar Fail2ban

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Crear configuración local (nunca editar el archivo .conf directamente)
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Buscar y ajustar en `jail.local`:
```ini
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
```

```bash
sudo systemctl restart fail2ban

# Verificar que está activo
sudo fail2ban-client status
```

---

## Paso 5 — Instalar Docker Engine

```bash
# Instalar dependencias
sudo apt install -y ca-certificates curl gnupg

# Agregar repositorio oficial de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Agregar tu usuario al grupo docker (para no usar sudo en cada comando)
sudo usermod -aG docker $USER

# Aplicar el cambio de grupo (o cierra sesión y vuelve a entrar)
newgrp docker

# Verificar instalación
docker --version
docker compose version
```

---

## Paso 6 — Instalar Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Verificar que funciona
sudo nginx -t
curl http://localhost  # Debe mostrar la página por defecto de Nginx
```

---

## Paso 7 — Instalar Certbot (SSL)

```bash
sudo apt install -y certbot python3-certbot-nginx

# Obtener certificado (reemplaza con tu dominio real)
sudo certbot --nginx -d tudominio.cl -d www.tudominio.cl

# Certbot configura la renovación automática — verificar que funciona
sudo certbot renew --dry-run
```

> **Requisito:** El dominio debe apuntar a la IP del servidor antes de correr Certbot. Si aún no tienes dominio, puedes usar un certificado autofirmado temporalmente para desarrollo:
> ```bash
> sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
>   -keyout /etc/ssl/private/thoth-selfsigned.key \
>   -out /etc/ssl/certs/thoth-selfsigned.crt
> ```

---

## Paso 8 — Configurar Nginx como Reverse Proxy

Crear el archivo de configuración de Thoth:

```bash
sudo nano /etc/nginx/sites-available/thoth
```

```nginx
# Redirigir HTTP → HTTPS
server {
    listen 80;
    server_name tudominio.cl www.tudominio.cl;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name tudominio.cl www.tudominio.cl;

    ssl_certificate     /etc/letsencrypt/live/tudominio.cl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tudominio.cl/privkey.pem;

    # Headers de seguridad
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

    # API Node.js
    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSockets
    location /ws/ {
        proxy_pass http://localhost:3000/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }

    # Frontend React (archivos estáticos)
    location / {
        root /var/www/thoth;
        try_files $uri $uri/ /index.html;
        expires 1d;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# Activar el sitio
sudo ln -s /etc/nginx/sites-available/thoth /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # Remover el sitio por defecto

# Verificar configuración
sudo nginx -t

# Recargar Nginx
sudo systemctl reload nginx
```

---

## Paso 9 — Estructura de Directorios del Proyecto

```bash
# Crear estructura en el servidor
sudo mkdir -p /opt/thoth/{data/postgres,data/redis,logs,backups,ssl}
sudo chown -R $USER:$USER /opt/thoth

# El código del proyecto irá aquí
mkdir -p /opt/thoth/app
```

Estructura final en el servidor:
```
/opt/thoth/
├── app/                    → código del proyecto (git clone aquí)
│   ├── docker-compose.yml
│   ├── .env                → variables de entorno (NUNCA en git)
│   └── ...
├── data/
│   ├── postgres/           → datos persistentes de PostgreSQL
│   └── redis/              → datos persistentes de Redis
├── logs/                   → logs de la aplicación
├── backups/                → backups de la base de datos
└── ssl/                    → certificados (si no usas Certbot)
```

---

## Paso 10 — Variables de Entorno

```bash
nano /opt/thoth/app/.env
```

```bash
# Base de datos
POSTGRES_DB=thoth
POSTGRES_USER=app_user
POSTGRES_PASSWORD=cambia_esto_por_password_seguro
DATABASE_URL=postgresql://app_user:cambia_esto@postgresql:5432/thoth

# Redis
REDIS_URL=redis://redis:6379

# JWT (generar con: openssl rand -base64 64)
JWT_SECRET=cambia_esto_por_secret_muy_largo

# Entorno
NODE_ENV=production
PORT=3000

# Python
PYTHON_SERVICE_URL=http://api-python:8000
PYTHON_SECRET=cambia_esto

# Email
SMTP_HOST=smtp.tuproveedor.cl
SMTP_PORT=587
SMTP_USER=notificaciones@tudominio.cl
SMTP_PASS=cambia_esto
```

---

## Paso 11 — Configurar Backups Automáticos

```bash
# Crear script de backup
nano /opt/thoth/backups/backup.sh
```

```bash
#!/bin/bash
FECHA=$(date +%Y%m%d_%H%M%S)
DESTINO="/opt/thoth/backups/db"
mkdir -p $DESTINO

# Hacer backup de PostgreSQL
docker exec thoth-postgresql pg_dump -U app_user thoth | \
  gzip > "$DESTINO/thoth_$FECHA.sql.gz"

# Eliminar backups con más de 30 días
find $DESTINO -name "*.sql.gz" -mtime +30 -delete

echo "Backup completado: thoth_$FECHA.sql.gz"
```

```bash
chmod +x /opt/thoth/backups/backup.sh

# Programar backup diario a las 3:00 AM
crontab -e
```

Agregar al crontab:
```
0 3 * * * /opt/thoth/backups/backup.sh >> /opt/thoth/logs/backup.log 2>&1
```

---

## Paso 12 — Monitoreo Básico del Sistema

```bash
# Instalar herramientas de monitoreo útiles
sudo apt install -y htop iotop nethogs ncdu

# Ver uso de CPU y RAM en tiempo real
htop

# Ver uso de disco
df -h
ncdu /opt/thoth

# Ver logs de Docker en tiempo real
docker compose -f /opt/thoth/app/docker-compose.yml logs -f

# Ver estado de todos los contenedores
docker ps

# Ver uso de recursos por contenedor
docker stats
```

---

---

## Trabajar en el Servidor Sin Interfaz Gráfica

Un servidor Ubuntu sin escritorio se administra completamente desde la terminal vía **SSH**. No hay ventanas, no hay mouse — solo comandos de texto. Esto puede parecer intimidante al principio, pero en la práctica el día a día se reduce a una docena de comandos que se memorizan rápido.

---

### Conectarse al Servidor (SSH)

Desde tu computador personal (Windows, Mac o Linux):

```bash
# Conectarse al servidor
ssh usuario@ip-del-servidor

# Si usas clave SSH (configurado en el Paso 3)
ssh -i ~/.ssh/id_ed25519 usuario@ip-del-servidor

# Ejemplo real
ssh -i ~/.ssh/thoth-server carlos@192.168.1.100
```

Una vez conectado, verás algo así:
```
carlos@thoth-server:~$
```
Eso significa que estás dentro del servidor. Todo lo que escribas se ejecuta ahí.

---

### Navegar el Servidor — Comandos Básicos

```bash
# ¿Dónde estoy?
pwd

# Ver archivos y carpetas del directorio actual
ls -la

# Entrar a una carpeta
cd /opt/thoth/app

# Volver atrás
cd ..

# Ver el contenido de un archivo
cat archivo.txt

# Ver un archivo largo página por página (q para salir)
less archivo.txt

# Editar un archivo de texto
nano archivo.txt
# Ctrl+O para guardar · Ctrl+X para salir

# Buscar texto dentro de archivos
grep -r "texto a buscar" /opt/thoth/

# Ver cuánto espacio queda en disco
df -h

# Ver uso de RAM y CPU en tiempo real
htop
# q para salir
```

---

### Administrar Docker desde la Terminal

```bash
# Ver todos los contenedores corriendo
docker ps

# Ver logs de un contenedor en tiempo real
docker compose logs -f api-node

# Reiniciar un contenedor
docker compose restart api-node

# Parar todos los contenedores
docker compose down

# Levantar todos los contenedores
docker compose up -d

# Reconstruir y redesplegar (después de actualizar código)
docker compose up -d --build

# Ver cuántos recursos consume cada contenedor
docker stats

# Entrar dentro de un contenedor
docker exec -it thoth-postgresql bash
```

---

### Opción Recomendada — VS Code con Remote-SSH

La forma más cómoda de trabajar en un servidor sin interfaz gráfica es **VS Code + extensión Remote-SSH**. Esto te da:

- Explorador visual de archivos del servidor
- Editor de texto con sintaxis resaltada
- Terminal SSH integrada
- Sin instalar nada extra en el servidor

**Instalación:**

1. Instalar [VS Code](https://code.visualstudio.com/) en tu computador personal
2. Instalar la extensión **Remote - SSH** (id: `ms-vscode-remote.remote-ssh`)
3. `Ctrl+Shift+P` → `Remote-SSH: Connect to Host`
4. Ingresar `usuario@ip-del-servidor`
5. VS Code se conecta — trabajas como si fuera tu máquina local

```
Tu computador personal
VS Code + Remote-SSH
        │
        │ SSH
        ▼
Servidor Thoth (/opt/thoth/app/)
```

> Esta es la herramienta que vas a usar el 90% del tiempo para editar configuraciones, revisar logs y trabajar con el código.

---

### Opción Alternativa — Panel Web con Portainer

Si prefieres administrar Docker desde un navegador, **Portainer** es un panel web gratuito:

```bash
docker volume create portainer_data

docker run -d \
  -p 9443:9443 \
  --name portainer \
  --restart=unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Abrir en el navegador: `https://ip-del-servidor:9443`

Desde Portainer puedes ver el estado de contenedores, logs y volúmenes con interfaz visual sin escribir comandos.

> Solo accesible desde tu red local — no exponer a internet.

---

### Mantener Sesiones Activas — tmux

Cuando trabajas por SSH y se cae la conexión o cierras la terminal, los procesos que estabas corriendo se detienen. **tmux** mantiene las sesiones activas aunque te desconectes:

```bash
# Instalar
sudo apt install -y tmux

# Crear una nueva sesión con nombre
tmux new -s thoth

# Volver a conectar a la sesión si te desconectaste
tmux attach -t thoth

# Ver sesiones activas
tmux ls

# Salir de tmux sin detenerlo (deja todo corriendo)
# Presionar: Ctrl+B, luego D
```

---

### Monitoreo Rápido

```bash
# CPU, RAM y procesos (como el administrador de tareas)
htop

# Qué proceso está usando más disco
iotop

# Tráfico de red por proceso
sudo nethogs

# Tamaño de carpetas
ncdu /opt/thoth

# Logs del sistema en tiempo real
sudo journalctl -f

# Últimas líneas del log de Nginx
sudo tail -f /var/log/nginx/error.log
```

---

### Resumen — Qué Herramienta Usar para Qué

| Tarea | Herramienta |
|-------|-------------|
| Editar código y archivos de config | VS Code + Remote-SSH |
| Ver estado de contenedores | `docker ps` o Portainer |
| Ver logs de la aplicación | `docker compose logs -f` |
| Monitorear CPU/RAM | `htop` |
| Correr comandos sin perder la sesión | tmux |
| Administración visual de Docker | Portainer (navegador) |

---

## Checklist Final Antes de Poner en Producción

### Seguridad
- [ ] SSH solo con clave pública (password desactivado)
- [ ] UFW activo — solo puertos 22, 80, 443 abiertos
- [ ] Fail2ban activo y monitoreando SSH
- [ ] SSL activo y redirigiendo HTTP → HTTPS
- [ ] Archivo `.env` con permisos 600: `chmod 600 /opt/thoth/app/.env`
- [ ] Passwords en `.env` son seguros (mínimo 32 caracteres aleatorios)
- [ ] PostgreSQL no expuesto en ningún puerto externo

### Sistema
- [ ] UPS conectado y funcionando
- [ ] Backups automáticos configurados y probados (hacer un restore de prueba)
- [ ] Crontab de backups activo: `crontab -l`
- [ ] Nginx con configuración verificada: `sudo nginx -t`
- [ ] Certbot con renovación automática: `sudo certbot renew --dry-run`

### Docker
- [ ] Todos los contenedores corriendo: `docker ps`
- [ ] Datos de PostgreSQL y Redis en volúmenes persistentes (no en el contenedor)
- [ ] Política de restart configurada (`restart: unless-stopped` en docker-compose.yml)
- [ ] Logs rotativos configurados para no llenar el disco

---

## Comandos de Uso Diario

```bash
# Ver estado de todos los servicios
docker ps

# Ver logs de un servicio específico
docker compose logs -f api-node
docker compose logs -f postgresql

# Reiniciar un servicio
docker compose restart api-node

# Actualizar y redesplegar
cd /opt/thoth/app
git pull
docker compose up -d --build

# Hacer backup manual ahora
/opt/thoth/backups/backup.sh

# Ver uso de disco
df -h && du -sh /opt/thoth/data/*

# Conectarse a PostgreSQL directamente
docker exec -it thoth-postgresql psql -U app_user -d thoth
```

---

*Ver [ARQUITECTURA.md](./ARQUITECTURA.md) para el contexto completo del stack.*
*Ver [BUENAS_PRACTICAS.md](./BUENAS_PRACTICAS.md) para convenciones de seguridad.*