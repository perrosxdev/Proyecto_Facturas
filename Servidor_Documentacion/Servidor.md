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

## Procesadores Recomendados

### Fase 1 (1–5 empresas, 40–50 usuarios)

| Procesador | Núcleos/Hilos | Comentarios |
|------------|--------------|-------------|
| AMD Ryzen 7 5700X | 8 / 16 | Excelente relación precio/rendimiento. |
| AMD Ryzen 7 7700 | 8 / 16 | Mayor eficiencia y plataforma moderna. |
| Intel Core i5-14500 | 14 núcleos / 20 hilos | Muy buen rendimiento multitarea. |
| Intel Core i7-12700 | 12 núcleos / 20 hilos | Excelente para múltiples contenedores. |

### Fase 2 (10–30 empresas, 100–200 usuarios)

| Procesador | Núcleos/Hilos | Comentarios |
|------------|--------------|-------------|
| AMD Ryzen 9 7900 | 12 / 24 | Muy recomendado para crecimiento a largo plazo. |
| AMD Ryzen 9 9900 | 12 / 24 | Excelente eficiencia y rendimiento. |
| Intel Core i7-14700 | 20 núcleos / 28 hilos | Gran capacidad de multitarea. |
| Intel Core i9-14900 | 24 núcleos / 32 hilos | Pensado para cargas elevadas y expansión futura. |

---

## Placas Madre Recomendadas

### Plataforma AMD AM4 (Ryzen 5000)

- Chipset B550.
- Soporte para SSD NVMe PCIe 4.0.
- Hasta 128 GB de RAM.
- Ejemplos:
  - ASUS TUF Gaming B550-PLUS
  - MSI MAG B550 Tomahawk
  - Gigabyte B550 AORUS Elite

### Plataforma AMD AM5 (Ryzen 7000/9000)

- Chipset B650.
- Soporte DDR5.
- Mayor vida útil de la plataforma.
- Ejemplos:
  - MSI B650 Tomahawk WiFi
  - ASUS TUF Gaming B650-PLUS
  - Gigabyte B650 AORUS Elite AX

### Plataforma Intel LGA1700

- Chipset B760.
- Compatible con i5/i7/i9 de 12ª a 14ª generación.
- Ejemplos:
  - MSI PRO B760-P
  - ASUS TUF B760-PLUS
  - Gigabyte B760 AORUS Elite

---

## Memoria RAM Recomendada

### Fase 1

- 32 GB (2×16 GB)
- DDR4-3200 (AM4)
- DDR5-5600 (AM5 o Intel)

### Fase 2

- 64 GB (2×32 GB)
- DDR5-5600 o superior.

> Se recomienda dejar dos ranuras libres para futuras ampliaciones.

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
| CPU | AMD Ryzen 7 5700X |
| Placa | MSI B550 Tomahawk |
| RAM | 32 GB DDR4 |
| SSD principal | 1 TB NVMe PCIe 4.0 |
| Disco respaldo | 1 TB SSD |
| Fuente | 650 W 80+ Bronze |
| GPU | No necesaria |
| UPS | 1500 VA |

---

## Configuración Recomendada (Escalamiento)

| Componente | Recomendación |
|-----------|---------------|
| CPU | AMD Ryzen 9 7900 |
| Placa | MSI B650 Tomahawk |
| RAM | 64 GB DDR5 |
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