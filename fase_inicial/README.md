# fase_inicial (historical)

First-pass notes for standing up nginx-rtmp on the VPS.

**The working multistream config is in [`../rtmp/`](../rtmp/)** (`nginx.conf.template`, `Containerfile`, `render-nginx-conf.sh`). See the root [README](../README.md).

Do not use the old 48 fps / `g=96` settings from earlier revisions of this directory. Those files were removed so they cannot contradict the live 60 fps / `g=120` VPS config.
