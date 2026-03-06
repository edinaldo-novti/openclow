#!/bin/bash
# Instala plugins de canais (Teams, Mattermost) no OpenClaw
# Execute após o primeiro docker compose up
set -e
cd "$(dirname "$0")/.."

echo "Instalando plugins OpenClaw..."
docker compose --profile cli run --rm --user root openclaw-cli plugins install @openclaw/msteams
docker compose --profile cli run --rm --user root openclaw-cli plugins install @openclaw/mattermost
echo "Plugins instalados. Reinicie o gateway: docker compose restart openclaw-gateway"
