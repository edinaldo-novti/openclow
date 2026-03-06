# OpenClaw Server - Infraestrutura Profissional

Servidor [OpenClaw](https://openclaw.ai) containerizado, resiliente e pronto para produção, integrado com os principais modelos de IA (OpenAI, Anthropic, Ollama/LocalAI).

## Estrutura do Projeto

```
openclow/
├── docker-compose.yml      # Orquestração dos serviços
├── .env.example            # Template de variáveis de ambiente
├── config/
│   ├── openclaw.json       # Config gateway + canais (Teams, Mattermost)
│   └── agent/              # Prompts do agente (Gemini)
│       ├── SOUL.md         # Identidade, personalidade, valores
│       └── AGENTS.md       # Regras de comportamento
├── scripts/
│   └── install-plugins.sh   # Instala plugins de canais
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD para Coolify
└── README.md
```

## Tech Stack

| Componente | Tecnologia |
|------------|------------|
| **Runtime** | Docker & Docker Compose |
| **Database** | PostgreSQL 16 + pgvector |
| **Cache** | Redis 7 Alpine |
| **Application** | OpenClaw Gateway (ghcr.io/openclaw/openclaw) |
| **Deployment** | Coolify (autogerenciado) |
| **CI/CD** | GitHub Actions |

## Pré-requisitos

- Docker Engine 20.10+
- Docker Compose v2
- 2 GB RAM mínimo (4 GB recomendado para produção)

## Inicialização Rápida

### 1. Clone e configure

```bash
git clone <seu-repo> openclow
cd openclow
cp .env.example .env
```

### 2. Edite o `.env`

```bash
# Obrigatório: gere um token seguro
OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)

# Adicione suas chaves de API
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Configure o PostgreSQL
POSTGRES_PASSWORD=CHANGE_ME_secure_password
```

### 3. Inicie os serviços

```bash
docker compose up -d
```

### 4. Execute o onboarding

```bash
docker compose --profile cli run --rm openclaw-cli onboard
```

### 5. Acesse o Control UI

- **URL:** `http://localhost:18789`
- **Token:** Cole o `OPENCLAW_GATEWAY_TOKEN` em Settings → Token

## Comandos Úteis

```bash
# Ver status
docker compose ps

# Logs do gateway
docker compose logs -f openclaw-gateway

# Dashboard (URL do Control UI)
docker compose --profile cli run --rm openclaw-cli dashboard --no-open

# Configurar canais (WhatsApp, Telegram, Discord)
docker compose --profile cli run --rm openclaw-cli channels login
docker compose --profile cli run --rm openclaw-cli channels add --channel telegram --token "<token>"

# Health check
curl -fsS http://localhost:18789/healthz
curl -fsS http://localhost:18789/readyz
```

## Integração com Coolify

### 1. Criar aplicação no Coolify

1. **Nova Aplicação** → **Docker Compose**
2. Conecte o repositório GitHub
3. Defina o caminho: `docker-compose.yml`
4. Configure o domínio: ex. `openclaw.seudominio.com`

### 2. Configurar variáveis

No painel do Coolify, adicione as variáveis do `.env` em **Environment Variables**.

**Importante:** Se usar credenciais PostgreSQL diferentes do default (`openclaw`/`openclaw_secure_password`), defina `DATABASE_URL` explicitamente: `postgresql://USER:SENHA@postgres:5432/DB`

### 3. Configurar Webhook (CI/CD)

1. **Settings** → **Advanced** → **API Access** (habilitar)
2. **Keys & Tokens** → Crie token com permissão **Deploy**
3. Na aplicação: **Webhook** → Copie a URL de deploy
4. No GitHub: **Settings** → **Secrets** → **Actions**:
   - `COOLIFY_WEBHOOK`: URL do webhook
   - `COOLIFY_TOKEN`: Token da API

### 4. Domínios e portas no Coolify

O Coolify gera o reverse proxy automaticamente. **Importante:** no campo de domínio do `openclaw-gateway`, use a porta para o proxy rotear corretamente:

- **openclaw-gateway:** `https://ia.nogui.com.br:18789` (a porta informa o loadbalancer; o acesso público continua via `https://ia.nogui.com.br`)
- **mattermost:** `https://bro.nogui.com.br:8065`
- **openclaw-init:** deixe vazio (não é serviço web)

## Canais de Chat

### Microsoft Teams

1. **Instale o plugin** (uma vez):
   ```bash
   ./scripts/install-plugins.sh
   docker compose restart openclaw-gateway
   ```

2. **Crie um Azure Bot** em [portal.azure.com](https://portal.azure.com/#create/Microsoft.AzureBot):
   - Tipo: Single Tenant
   - Copie: App ID, Client Secret, Tenant ID

3. **Configure o webhook** no Azure Bot → Configuration:
   - Messaging endpoint: `https://seu-dominio.com/api/messages` (ou use ngrok para dev)

4. **Habilite o canal Teams** no Azure Bot → Channels

5. **Adicione ao `.env`**:
   ```
   MSTEAMS_APP_ID=seu-app-id
   MSTEAMS_APP_PASSWORD=seu-client-secret
   MSTEAMS_TENANT_ID=seu-tenant-id
   ```

6. **Ative no config** (`config/openclaw.json`): `"msteams": { "enabled": true }`

Docs: [OpenClaw Microsoft Teams](https://docs.openclaw.ai/channels/msteams)

### Mattermost (chat self-hosted)

Chat open-source popular na comunidade. Deploy junto com o ambiente:

```bash
# Subir com Mattermost
docker compose --profile mattermost up -d

# Instalar plugin
./scripts/install-plugins.sh
docker compose restart openclaw-gateway
```

1. **Acesse** `http://localhost:8065` e crie a primeira conta (admin)

2. **Crie um Bot** em Mattermost:
   - Integrations → Bot Accounts → Add Bot Account
   - Copie o token

3. **Configure no `.env`**:
   ```
   MATTERMOST_BOT_TOKEN=seu-token
   MATTERMOST_BASE_URL=http://mattermost:8065
   MATTERMOST_SITE_URL=http://localhost:8065  # ou seu domínio público
   ```

4. **Ative no config** (`config/openclaw.json`): `"mattermost": { "enabled": true }`

5. **Adicione o bot** ao canal desejado e mencione `@nome-do-bot` para conversar

Docs: [OpenClaw Mattermost](https://docs.openclaw.ai/channels/mattermost)

### Outros canais

OpenClaw suporta também: **Telegram**, **Discord**, **Slack**, **WhatsApp**, **Google Chat**, **Matrix**, **Nextcloud Talk**, entre outros. Use `openclaw channels add` ou o wizard de onboarding.

## Integração com Modelos de IA

### OpenAI / Anthropic / Gemini

Defina no `.env`:

```
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...   # https://aistudio.google.com/apikey
```

**Gemini:** Chave em [Google AI Studio](https://aistudio.google.com/apikey). Modelos: `google/gemini-3-pro-preview`, `google/gemini-2.5-flash`, `google/gemini-2.5-pro`. Para definir como padrão: `docker compose --profile cli run --rm openclaw-cli models set google/gemini-2.5-flash`

### Personalizar o agente (SOUL.md / AGENTS.md)

Os prompts do agente ficam em `config/agent/`:

- **SOUL.md** — Identidade, personalidade, valores e limites do agente
- **AGENTS.md** — Regras de comportamento, memória e ferramentas

Edite esses arquivos para ajustar o tom, estilo e regras do assistente. Após alterar, reinicie o gateway: `docker compose restart openclaw-gateway`

### Ollama (modelos locais)

Para Ollama rodando no **host** (fora do Docker):

```
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

**Linux:** O `host.docker.internal` usa `host-gateway` (já configurado no compose). Em alguns ambientes, use o IP do host:

```
OLLAMA_BASE_URL=http://172.17.0.1:11434
```

### LocalAI

```
LOCALAI_BASE_URL=http://host.docker.internal:8080/v1
```

## Networks

| Rede | Uso |
|------|-----|
| `frontend` | Gateway (acesso externo) |
| `backend` | PostgreSQL, Redis, comunicação interna |

## Volumes Persistentes

| Volume | Descrição |
|--------|-----------|
| `openclaw_data` | Estado, canvas, cron e workspace do OpenClaw |
| `postgres_data` | Dados do PostgreSQL |
| `redis_data` | Dados do Redis |
| `mattermost_*` | Dados do Mattermost (se usar) |

## Solução de Problemas

### Erro EISDIR ou EACCES no Coolify

- **EISDIR** em `openclaw.json`: o config é copiado de `./config` ou gerado inline; garanta que `config/openclaw.json` exista no repositório.
- **EACCES** em `canvas` ou `cron`: o projeto usa volume nomeado `openclaw_data` em vez de bind mount para evitar problemas de permissão.

## Segurança

- **Reverse Proxy:** Rode sempre atrás de um proxy (Coolify, Traefik, Nginx)
- **Firewall:** Exponha apenas as portas necessárias (18789, 18790)
- **Secrets:** Nunca commite o `.env` — use secrets do Coolify/GitHub
- **PostgreSQL:** Use senha forte em produção

## Referências

- [OpenClaw Install](https://openclaws.io/install)
- [OpenClaw Docs](https://docs.openclaw.ai/start/getting-started)
- [OpenClaw Docker](https://docs.openclaw.ai/install/docker)
- [Coolify GitHub Actions](https://coolify.io/docs/applications/ci-cd/github/actions)

## Licença

MIT
