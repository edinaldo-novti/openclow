#!/bin/sh
# Garante openclaw.json válido antes de iniciar (evita EISDIR no Coolify)
# Quando ./config não existe ou openclaw.json é diretório, usa config padrão

set -e
CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/openclaw.json"
SOURCE_FILE="/config-source/openclaw.json"

mkdir -p "${CONFIG_DIR}"

if [ -f "${SOURCE_FILE}" ]; then
  cp "${SOURCE_FILE}" "${CONFIG_FILE}"
else
  cat > "${CONFIG_FILE}" << 'EOF'
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "enabled": true,
      "dangerouslyAllowHostHeaderOriginFallback": true
    }
  },
  "agents": {
    "defaults": {
      "model": { "primary": "google/gemini-2.5-flash" }
    }
  }
}
EOF
fi

# Gateway: command já é [node, dist/index.js, gateway, ...] -> exec "$@"
# CLI: command é [onboard] ou similar -> exec node dist/index.js "$@"
if [ "$1" = "node" ]; then
  exec "$@"
else
  exec node dist/index.js "$@"
fi
