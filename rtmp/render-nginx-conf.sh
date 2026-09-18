#!/usr/bin/env bash
# Render rtmp/nginx.conf from nginx.conf.template using stream keys in .env.
# Substitutes only YOUTUBE_STREAM_KEY, TWITCH_STREAM_KEY, and KICK_STREAM_KEY
# so nginx-rtmp's $name is left intact.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE="${SCRIPT_DIR}/nginx.conf.template"
OUTPUT="${NGINX_CONF_OUT:-${SCRIPT_DIR}/nginx.conf}"
ENV_FILE="${ENV_FILE:-${REPO_ROOT}/.env}"
REQUIRED_KEYS=(YOUTUBE_STREAM_KEY TWITCH_STREAM_KEY KICK_STREAM_KEY)

if [[ ! -f "${TEMPLATE}" ]]; then
  echo "error: template not found: ${TEMPLATE}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "error: ${ENV_FILE} not found. Run: install -m 600 .env.example .env" >&2
  exit 1
fi

load_env() {
  local line key value
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
    if [[ "${line}" != *=* ]]; then
      echo "error: invalid line in ${ENV_FILE}: ${line}" >&2
      exit 1
    fi
    key="${line%%=*}"
    value="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    key="${key#"${key%%[![:space:]]*}"}"
    if [[ "${value}" == \"*\" || "${value}" == \'*\' ]]; then
      value="${value:1:${#value}-2}"
    fi
    case "${key}" in
      YOUTUBE_STREAM_KEY|TWITCH_STREAM_KEY|KICK_STREAM_KEY)
        export "${key}=${value}"
        ;;
    esac
  done < "${ENV_FILE}"
}

# Ignore keys already exported in the caller shell; only .env counts.
unset "${REQUIRED_KEYS[@]}"
load_env

for key in "${REQUIRED_KEYS[@]}"; do
  if [[ -z "${!key:-}" ]]; then
    echo "error: ${key} is empty or missing in ${ENV_FILE}" >&2
    exit 1
  fi
done

tmp=""
cleanup() {
  if [[ -n "${tmp}" && -e "${tmp}" ]]; then
    rm -f "${tmp}"
  fi
}
trap cleanup EXIT

umask 077
mkdir -p "$(dirname "${OUTPUT}")"
tmp="$(mktemp "${OUTPUT}.XXXXXX")"

if command -v envsubst >/dev/null 2>&1; then
  envsubst '${YOUTUBE_STREAM_KEY} ${TWITCH_STREAM_KEY} ${KICK_STREAM_KEY}' \
    < "${TEMPLATE}" > "${tmp}"
else
  python3 - "${TEMPLATE}" "${tmp}" <<'PY'
import os
import pathlib
import sys

template_path, output_path = sys.argv[1], sys.argv[2]
text = pathlib.Path(template_path).read_text()
for key in ("YOUTUBE_STREAM_KEY", "TWITCH_STREAM_KEY", "KICK_STREAM_KEY"):
    text = text.replace("${%s}" % key, os.environ[key])
pathlib.Path(output_path).write_text(text)
PY
fi

if grep -qE '\$\{(YOUTUBE_STREAM_KEY|TWITCH_STREAM_KEY|KICK_STREAM_KEY)\}' "${tmp}"; then
  echo "error: placeholders remain in rendered output; substitution failed." >&2
  exit 1
fi

chmod 600 "${tmp}"
mv -f "${tmp}" "${OUTPUT}"
tmp=""
chmod 600 "${OUTPUT}"

echo "Wrote ${OUTPUT} (mode 0600, gitignored). Do not commit this file or copy it into git."
echo "On the VPS, keep the live copy at /opt/rtmp/nginx.conf out of version control."
