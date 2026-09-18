# Podman notes (historical)

Canonical steps live in the root [README](../README.md). This file keeps the original VPS runbook, pointed at `rtmp/`.

## Pre-requisitos

- Validar SO del VPS
- Abrir puertos **1935** y **8080**
- Instalar dependencias: git curl wget vim tar unzip net-tools nmap-ncat podman gettext (o Python 3)

## Generar nginx.conf (sin keys en git)

```bash
install -m 600 .env.example .env
# llenar YOUTUBE_STREAM_KEY, TWITCH_STREAM_KEY, KICK_STREAM_KEY
./rtmp/render-nginx-conf.sh
# opcional en el VPS:
# NGINX_CONF_OUT=/opt/rtmp/nginx.conf ./rtmp/render-nginx-conf.sh
```

`/opt/rtmp/nginx.conf` se genera en el host y **no** se commitea.

## Build

```bash
cd rtmp
sudo podman build -t nginx-rtmp-ffmpeg -f Containerfile .
```

## Remover container

```bash
sudo podman rm -f rtmp 2>/dev/null || true
```

## Correr contenedor (known-good VPS)

```bash
sudo podman run -d --name rtmp --network=host \
  --ulimit nofile=1048576:1048576 \
  --cpus=8 --memory=8g --cpuset-cpus=0-7 \
  --restart=always --user 0:0 \
  nginx-rtmp-ffmpeg
```

## Lanzar stream

OBS (Windows 11): Server `rtmp://<VPS_IP>:1935/live`, Stream Key = nombre de publicación (por ejemplo `main`).

## Comandos extra

```bash
sudo podman exec -it rtmp nginx -t
sudo podman logs -f rtmp
sudo podman stats rtmp
```
