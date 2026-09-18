# vps-streaming-setup

Source of truth for the **working** VPS multistream stack: Podman + `alfg/nginx-rtmp` + FFmpeg.

OBS on Windows 11 publishes one RTMP ingest. The server fans that out to **YouTube** (passthrough push), **Twitch**, and **Kick** (FFmpeg restream at **60 fps / GOP 120**). This matches the known-good config on the IONOS VPS under `/opt/rtmp/`.

TikTok is left commented, as on the live server. Do not invent TikTok keys.

## Requirements

- AlmaLinux 8 (tested first) or similar; Podman 4.x
- `podman-compose` if you use `compose.yml`
- `envsubst` (gettext) or Python 3, to render `nginx.conf`
- Firewall: **TCP 1935** (RTMP ingest) and **TCP 8080** (`/stat`)

Rootless is fine for experiments. The known-good VPS run is rootful with `--user 0:0` because the image installs FFmpeg as root and nginx runs as `user root`.

## Secret handling

Platform stream keys exist **only** on the VPS (or in your local `.env`). They must never land in git.

| File | In git? |
| --- | --- |
| `rtmp/nginx.conf.template` | Yes — placeholders only |
| `.env.example` | Yes — empty key names |
| `.env` | **No** (gitignored) |
| `rtmp/nginx.conf` (rendered) | **No** (gitignored) |
| `/opt/rtmp/nginx.conf` on the VPS | **No** — generate locally, keep it off git |

Render the live config from the template (restricted substitution so nginx-rtmp's `$name` is not eaten):

```bash
cp .env.example .env
# edit .env — set YOUTUBE_STREAM_KEY, TWITCH_STREAM_KEY, KICK_STREAM_KEY
chmod +x rtmp/render-nginx-conf.sh
./rtmp/render-nginx-conf.sh
```

On the VPS you can write the live path directly:

```bash
NGINX_CONF_OUT=/opt/rtmp/nginx.conf ./rtmp/render-nginx-conf.sh
```

`alfg/nginx-rtmp` re-runs `envsubst` at container start from `nginx.conf.template`. After a local render the keys are already baked in. Do **not** export an environment variable named `name`, or the image will wipe nginx-rtmp's `$name`.

## OBS (Windows 11) → VPS

1. Settings → Stream
2. Service: **Custom**
3. Server: `rtmp://<VPS_IP>:1935/live`
4. Stream key: any publish name, e.g. `main`

Full URL: `rtmp://<VPS_IP>:1935/live/<stream_name>`

That `<stream_name>` is **not** a YouTube/Twitch/Kick key. It becomes `$name` inside nginx-rtmp. Platform keys stay in `.env`.

Recommended OBS output to match the restream: **60 fps**, enough bitrate for YouTube passthrough (Twitch is capped at 6000k, Kick at 7000k by FFmpeg).

## Quick start (compose)

1. Copy `.env.example` → `.env` and fill the three stream keys.
2. `./rtmp/render-nginx-conf.sh` (creates gitignored `rtmp/nginx.conf`).
3. `podman-compose up -d --build`
4. Publish from OBS to `rtmp://<VPS_IP>:1935/live/<STREAM_NAME>`
5. Check `http://<VPS_IP>:8080/stat`

Rebuild the image after you change the rendered `nginx.conf` only if you are not bind-mounting it. This compose file mounts the rendered file, so a container restart is enough.

## Known-good VPS run (Podman)

This is the production-shaped command from `/opt/rtmp/` (host network, FFmpeg + nginx-rtmp image):

```bash
cd rtmp
# rtmp/nginx.conf must already be rendered from the template
sudo podman build -t nginx-rtmp-ffmpeg -f Containerfile .

sudo podman rm -f rtmp 2>/dev/null || true
sudo podman run -d --name rtmp \
  --network=host \
  --ulimit nofile=1048576:1048576 \
  --cpus=8 --memory=8g --cpuset-cpus=0-7 \
  --restart=always --user 0:0 \
  nginx-rtmp-ffmpeg
```

Useful checks:

```bash
sudo podman exec -it rtmp nginx -t
sudo podman logs -f rtmp
sudo podman stats rtmp
```

Open ports on firewalld if needed:

```bash
sudo firewall-cmd --permanent --add-port=1935/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## Layout

| Path | Role |
| --- | --- |
| `rtmp/nginx.conf.template` | Working 60 fps multistream config (placeholders) |
| `rtmp/render-nginx-conf.sh` | Renders gitignored `rtmp/nginx.conf` |
| `rtmp/Containerfile` | Same recipe as the VPS: `alfg/nginx-rtmp` + Alpine `ffmpeg` |
| `compose.yml` | Build + publish 1935 / 8080 |
| `fase_inicial/` | Historical first-pass notes only |

The old ingest-only stub that used to live at `rtmp/nginx.conf` is gone so it cannot contradict this config.

## Encoding (matches live VPS)

- YouTube: `push` of the original ingest (no FFmpeg)
- Twitch: libx264 `veryfast` / `zerolatency` / high / **60 fps, g=120**, 6000k
- Kick: same encode family at **7000k**, RTMPS ingest
- TikTok: commented; still the old 48 fps line if you ever enable it yourself

## What this repo does not do

- No live keys, no TikTok keys
- `/stat` has no authentication (same as the known-good VPS file)
- Hardening (rootless, read-only rootfs, auth on `/stat`) is still future work
