---

## Trabajar en el Servidor sin Interfaz Gráfica

Ubuntu Server no tiene escritorio — todo se hace desde la terminal vía SSH. Esto es lo estándar en servidores y tiene ventajas concretas: menos consumo de RAM, menos superficie de ataque y mayor estabilidad.

### Conectarse al servidor

Desde tu máquina (Windows, Mac o Linux):

```bash
ssh usuario@ip-del-servidor

# Con puerto personalizado
ssh -p 2222 usuario@ip-del-servidor

# Con clave específica
ssh -i ~/.ssh/thoth-server usuario@ip-del-servidor
```

En Windows puedes usar Windows Terminal con OpenSSH nativo (recomendado, viene con Windows 10/11), PuTTY, o MobaXterm (tiene explorador de archivos SFTP integrado).

---

### Comandos esenciales de navegación

```bash
pwd           # ver dónde estás
ls -la        # listar archivos con detalles
cd /opt/thoth # entrar a una carpeta
cd ..         # subir un nivel
cd ~          # ir al home
clear         # limpiar pantalla
```

---

### Editar archivos: nano

Sin interfaz gráfica la opción más simple es **nano**:

```bash
nano /opt/thoth/app/.env

# Atajos dentro de nano:
# Ctrl+O  → guardar
# Ctrl+X  → salir
# Ctrl+W  → buscar
# Ctrl+K  → cortar línea
# Ctrl+U  → pegar línea
```

### Editar desde VS Code (recomendado)

La extensión **Remote - SSH** de VS Code te permite abrir carpetas del servidor directamente en tu editor local — editas, guardas, y el cambio queda en el servidor sin copiar nada manualmente:

```
VS Code → Extensions → buscar "Remote - SSH" → instalar
F1 → "Remote-SSH: Connect to Host" → usuario@ip-del-servidor
```

Es la forma más cómoda de trabajar en el proyecto desde tu máquina.

---

### Subir y bajar archivos

```bash
# Subir archivo local al servidor
scp archivo.env usuario@ip-del-servidor:/opt/thoth/app/.env

# Subir carpeta completa
scp -r ./carpeta usuario@ip-del-servidor:/opt/thoth/

# Bajar archivo del servidor
scp usuario@ip-del-servidor:/opt/thoth/logs/app.log ./
```

Para una interfaz visual, **FileZilla** funciona con SFTP (mismo puerto SSH, sin configuración extra).

---

### Ver logs y buscar en archivos

```bash
# Ver archivo completo
cat archivo.log

# Ver página por página (q para salir)
less archivo.log

# Ver últimas 50 líneas
tail -n 50 archivo.log

# Ver logs en tiempo real
tail -f /opt/thoth/logs/app.log

# Buscar texto en un archivo
grep "ERROR" archivo.log

# Buscar en todos los archivos de una carpeta
grep -r "ERROR" /opt/thoth/logs/
```

---

### Monitorear recursos

```bash
htop              # CPU y RAM en tiempo real (q para salir)
df -h             # uso de disco por partición
du -sh /opt/thoth/* # espacio por carpeta
docker stats      # uso de recursos por contenedor Docker
```

---

### Gestionar servicios

```bash
sudo systemctl status nginx      # ver estado
sudo systemctl restart nginx     # reiniciar
sudo systemctl enable nginx      # iniciar automáticamente al encender
sudo systemctl list-units --type=service --state=running  # todos los activos
```

---

### Sesiones persistentes con tmux

El problema de SSH: si se cae la conexión, los procesos se detienen. **tmux** crea sesiones que siguen corriendo aunque te desconectes.

```bash
# Instalar
sudo apt install -y tmux

# Crear sesión
tmux new -s thoth

# Atajos (prefijo: Ctrl+B):
# Ctrl+B + D  → desconectarse (la sesión sigue corriendo)
# Ctrl+B + C  → nueva ventana
# Ctrl+B + N  → siguiente ventana
# Ctrl+B + %  → dividir pantalla vertical
# Ctrl+B + "  → dividir pantalla horizontal

# Reconectarse a la sesión
tmux attach -t thoth

# Ver sesiones activas
tmux ls
```

**Flujo recomendado:** al conectarte, siempre abre tmux primero:

```bash
tmux attach -t thoth 2>/dev/null || tmux new -s thoth
```

Puedes tener varias ventanas abiertas simultáneamente — una con logs en tiempo real, otra con htop, otra para comandos generales.

---

### Apagar y reiniciar el servidor

```bash
sudo reboot                   # reiniciar
sudo shutdown -h now          # apagar ahora
sudo shutdown -h +10          # apagar en 10 minutos
sudo shutdown -c              # cancelar apagado programado
```

---