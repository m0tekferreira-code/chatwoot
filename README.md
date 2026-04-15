# Chatwoot – Instalação em VPS Ubuntu

Plataforma de atendimento ao cliente open-source, alternativa ao Intercom, Zendesk e Salesforce Service Cloud.

Este guia cobre a instalação completa do Chatwoot em uma **VPS Ubuntu** usando **Docker com imagem personalizada**.

---

## Pré-requisitos

| Requisito | Mínimo | Recomendado |
|-----------|--------|-------------|
| **Sistema** | Ubuntu 20.04 | Ubuntu 22.04 ou 24.04 |
| **RAM** | 2 GB | 4 GB+ |
| **Disco** | 10 GB livres | 20 GB+ |
| **Portas** | 80, 443 abertas | 80, 443, 22 |
| **Domínio** | Subdomínio apontando para o IP da VPS | `chat.seudominio.com` |
| **Acesso** | root ou sudo | root |

## Configuração de DNS

Antes de iniciar, aponte seu domínio/subdomínio para o IP da VPS:

1. Acesse o painel DNS do seu registrador (GoDaddy, Namecheap, RegistroBR, etc.)
2. Crie um registro **A**:

```
Nome:   chat.seudominio.com
Tipo:   A
Valor:  IP_DA_SUA_VPS
TTL:    3600
```

3. Verifique a propagação:

```bash
nslookup chat.seudominio.com
```

> Use subdomínio (`chat.seudominio.com`) em vez de domínio raiz para maior flexibilidade e isolamento.

Para configuração detalhada, veja [DOMAIN_SETUP.md](./DOMAIN_SETUP.md).

---

## Instalação Rápida (Script Automatizado)

### Opção 1: Upload + execução manual

```bash
# No seu computador — envie o script para a VPS
scp setup_vps.sh root@seu-servidor:/root/

# Conecte na VPS
ssh root@seu-servidor

# Execute
sudo bash setup_vps.sh
```

### Opção 2: Usando o deploy helper

**Linux/macOS:**
```bash
bash deploy.sh
```

**Windows (PowerShell):**
```powershell
.\deploy.ps1
```

Os helpers pedem host, usuário e porta SSH, fazem o upload e executam o script automaticamente.

### O que o script pergunta

| Pergunta | Exemplo |
|----------|---------|
| Domínio/URL | `chat.seudominio.com` |
| Email para SSL | `admin@seudominio.com` |
| Email do administrador | `seu-email@empresa.com` |
| Nome do administrador | `João Silva` |
| Senha do administrador | Mín. 6 caracteres |

Senhas do PostgreSQL, Redis e Rails são geradas automaticamente (32 caracteres).

### O que o script instala

- Docker e Docker Compose
- Nginx como reverse proxy
- Certificado SSL (Let's Encrypt) com renovação automática
- PostgreSQL 16 (com pgvector)
- Redis
- Chatwoot (Rails + Sidekiq) via imagem Docker personalizada
- Scripts de backup e atualização
- Cron de backup diário às 02:00

Tempo estimado: **15–20 minutos**.

---

## Imagem Docker Personalizada

Este projeto **não usa a imagem oficial** `chatwoot/chatwoot` do Docker Hub. O `docker-compose.production.yaml` constrói uma imagem customizada a partir do código-fonte local.

### Como funciona

O arquivo `docker-compose.production.yaml` define:

```yaml
services:
  base: &base
    build:
      context: .
      dockerfile: docker/Dockerfile
    image: chatwoot-custom:latest
```

Todos os serviços (`rails`, `sidekiq`) herdam desta base. A imagem `chatwoot-custom:latest` é construída localmente com suas personalizações.

### Build manual da imagem

```bash
cd /opt/chatwoot

# Build da imagem personalizada
docker compose -f docker-compose.production.yaml build

# Verificar a imagem
docker images | grep chatwoot-custom
```

### Rebuild após alterações no código

Sempre que modificar o código-fonte, rebuild a imagem:

```bash
cd /opt/chatwoot

# Rebuild sem cache (garante código atualizado)
docker compose -f docker-compose.production.yaml build --no-cache

# Recriar os containers com a nova imagem
docker compose -f docker-compose.production.yaml up -d
```

### Personalizar o Dockerfile

O Dockerfile está em `docker/Dockerfile` e usa multi-stage build:

1. **pre-builder** — Instala dependências Ruby + Node, compila assets
2. **final** — Imagem enxuta só com runtime

Para adicionar dependências do sistema na imagem final:

```dockerfile
# Em docker/Dockerfile, na etapa final (após "FROM ruby:3.4.4-alpine3.21")
RUN apk add --no-cache sua-dependencia
```

### Usar um registry privado (opcional)

Se quiser publicar sua imagem personalizada:

```bash
# Tag com seu registry
docker tag chatwoot-custom:latest seu-registry.com/chatwoot-custom:latest

# Push
docker push seu-registry.com/chatwoot-custom:latest
```

Depois altere o `docker-compose.production.yaml`:

```yaml
services:
  base: &base
    image: seu-registry.com/chatwoot-custom:latest
```

---

## Estrutura de Arquivos na VPS

Após a instalação:

```
/opt/chatwoot/
├── .env                             # Variáveis de ambiente
├── docker-compose.production.yaml
├── docker/
│   └── Dockerfile                   # Dockerfile personalizado
├── app/                             # Código-fonte
├── backups/                         # Backups automáticos
└── logs/                            # Logs de instalação

/etc/nginx/sites-available/chatwoot  # Config do Nginx
/usr/local/bin/backup-chatwoot.sh    # Script de backup
/usr/local/bin/update-chatwoot.sh    # Script de atualização
```

---

## Comandos Úteis Pós-Instalação

### Gerenciar serviços

```bash
cd /opt/chatwoot

# Ver status dos containers
docker compose ps

# Ver logs em tempo real
docker compose logs -f rails

# Parar todos os serviços
docker compose down

# Iniciar todos os serviços
docker compose up -d

# Reiniciar um serviço específico
docker compose restart rails
docker compose restart sidekiq
```

### Console Rails

```bash
cd /opt/chatwoot
docker compose exec rails bundle exec rails console
```

### Backup manual

```bash
/usr/local/bin/backup-chatwoot.sh
ls -lah /opt/chatwoot/backups/
```

### Atualizar Chatwoot

```bash
/usr/local/bin/update-chatwoot.sh
```

O script de atualização faz backup antes, rebuild da imagem, executa migrations e reinicia os serviços.

---

## Configuração do `.env`

O arquivo `/opt/chatwoot/.env` contém todas as variáveis. Para editar:

```bash
nano /opt/chatwoot/.env
```

Após editar, reinicie:

```bash
cd /opt/chatwoot
docker compose restart rails sidekiq
```

### SMTP (envio de emails)

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=seu-email@gmail.com
SMTP_PASSWORD=sua-senha-de-app
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
```

### S3 (armazenamento de anexos)

```env
S3_BUCKET_NAME=seu-bucket
AWS_ACCESS_KEY_ID=sua-chave
AWS_SECRET_ACCESS_KEY=seu-secret
AWS_REGION=us-east-1
```

### Sentry (monitoramento de erros)

```env
SENTRY_DSN=sua-dsn-do-sentry
```

---

## Reinstalação / Reparo

Se precisar rodar o script novamente:

```bash
sudo bash setup_vps.sh
```

O script detecta instalações anteriores e oferece:

1. **ATUALIZAR** — Limpa configs e reinstala (recomendado)
2. **REPAIR** — Mantém dados e repara configurações
3. **CANCELAR** — Sai sem fazer nada

---

## Segurança

O script já configura:

- Senhas seguras de 32 caracteres (PostgreSQL, Redis, Rails)
- Certificado SSL com renovação automática
- Headers de segurança HTTP no Nginx
- Arquivo `.env` com permissões 600
- Debug desabilitado em produção

### Recomendações adicionais

```bash
# Configurar firewall
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Instalar fail2ban
apt-get install -y fail2ban
systemctl enable fail2ban
```

---

## Troubleshooting

### Aplicação não responde

```bash
cd /opt/chatwoot
docker compose logs -f rails
docker compose restart
```

### Certificado SSL expirado

```bash
certbot renew --force-renewal
```

### Porta em uso

```bash
lsof -i :80
lsof -i :443
```

Para mais cenários, veja [TROUBLESHOOTING_VPS.md](./TROUBLESHOOTING_VPS.md).

---

## Documentação Complementar

| Documento | Descrição |
|-----------|-----------|
| [SETUP_VPS.md](./SETUP_VPS.md) | Guia completo de instalação |
| [SETUP_VPS_QUICK_START.md](./SETUP_VPS_QUICK_START.md) | Quick start e re-execução |
| [DOMAIN_SETUP.md](./DOMAIN_SETUP.md) | Configuração de domínio/DNS |
| [TROUBLESHOOTING_VPS.md](./TROUBLESHOOTING_VPS.md) | Resolução de problemas |
| [SECURITY.md](./SECURITY.md) | Política de segurança |

## Licença

*Chatwoot* &copy; 2017-2026, Chatwoot Inc - Released under the MIT License.
