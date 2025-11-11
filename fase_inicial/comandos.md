# Guia para crear un servicio con Podman y levantar NGINX-RTMP-FFMPEG:

## Pre-requisitos y comandos:

### PASO 0: Configuraciones en VPS

- Validar SO del VPS
- Abrir puertos 1935 y 8080
- Instalar dependencias: git curl wget vim tar unzip net-tools nmap-ncat podman

### PASO 1: Build de la imagen con Containerfile

```bash
sudo podman build -t nginx-rtmp-ffmpeg .
```

### PASO 2: Remover container

```bash
sudo podman rm -f rtmp
sudo podman rm -f rtmp 2>/dev/null || true
```

### PASO 3: Correr contenedo

```bash
sudo podman run -d --name rtmp --network=host --ulimit nofile=1048576:1048576 --cpus=8 --memory=8g --cpuset-cpus=0-7 --restart=always --user 0:0 nginx-rtmp-ffmpeg
```

### PASO 4: Lanzar stream

- Lanza tu stream desde OBS, VLC o la plataforma que prefieras.

#### NOTAS: Comandos extra funcionales

```bash
sudo podman exec -it rtmp nginx -t # Validar sintaxis y existencia del nginx.conf adentro del contenedor
sudo podman logs -f rtmp # Leer logs del container
sudo podman stats rtmp # Leer el performance del container
```
