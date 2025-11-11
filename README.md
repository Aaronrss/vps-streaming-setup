# vps-streaming-setup

Deploy an RTMP ingest + FFmpeg pipeline on a VPS using **Podman**.  
Goal: clone, set stream variables, `podman-compose up -d`, and go live.

## Requirements

- AlmaLinux 8 (tested first), Podman 4.x, podman-compose
- Ports: TCP 1935 open on the VPS firewall (firewalld/iptables)
- Rootless recommended

## Quick start

1. Copy `.env.example` to `.env` and fill the variables.
2. `podman-compose up -d`
3. Push your stream to: `rtmp://<YOUR_VPS_IP>/live/<STREAM_NAME>`

## Next steps (roadmap)

- Multi-platform outputs (Twitch/YouTube/Kick)
- Transcoding profiles + ABR ladders
- Security hardening: rootless, read-only FS, seccomp, no-new-privs, healthchecks
- Monitoring/logging and auto-restart policies
