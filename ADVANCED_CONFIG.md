# 📚 Chatwoot VPS - Guias e Configurações Avançadas

## 🗂️ Arquivos de Deploy

| Arquivo | Descrição |
|---------|-----------|
| **setup_vps.sh** | Script principal de instalação completa |
| **deploy.sh** | Helper bash para upload e execução remota |
| **deploy.ps1** | Helper PowerShell para upload e execução remota |
| **health_check.sh** | Script de verificação de saúde do sistema |
| **SETUP_VPS.md** | Documentação completa da instalação |

## 🚀 Quick Start

### Linux/macOS
```bash
# 1. Dar permissão de execução
chmod +x setup_vps.sh deploy.sh health_check.sh

# 2. Executar deploy helper
bash deploy.sh

# 3. Seguir as instruções interativas
```

### Windows PowerShell
```powershell
# 1. Executar deploy helper
.\deploy.ps1

# 2. Seguir as instruções interativas
```

### Direct (sem helper)
```bash
# Via HTTPS (mais fácil)
ssh root@seu-server.com 'bash -s' < setup_vps.sh
```

## 🔧 Configurações Avançadas

### 1. Ambiente Multi-Tenant

Para hospedar múltiplos clientes:

```bash
# Editar .env
ENABLE_ACCOUNT_SIGNUP=true
ENABLE_ACCOUNT_DELETION=false
MULTI_TENANT_SETUP=true

# Reiniciar
docker compose restart rails sidewiq
```

### 2. Domínios Customizados por Cliente

```nginx
# Adicionar em /etc/nginx/sites-available/chatwoot

server {
    listen 443 ssl http2;
    server_name cliente1.com;
    
    ssl_certificate /etc/letsencrypt/live/cliente1.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cliente1.com/privkey.pem;
    
    location / {
        proxy_pass http://chatwoot;
        proxy_set_header X-Forwarded-Host cliente1.com;
        # ... resto da config
    }
}
```

Depois executar: `certbot certonly -d cliente1.com --webroot`

### 3. Integração com AWS S3

```bash
# 1. Criar bucket S3
aws s3 mb s3://chatwoot-files

# 2. Editar .env
S3_BUCKET_NAME=chatwoot-files
AWS_ACCESS_KEY_ID=sua-chave-aqui
AWS_SECRET_ACCESS_KEY=seu-secret-aqui
AWS_REGION=us-east-1

# 3. Reiniciar rails
docker compose restart rails
```

### 4. SMTP com Gmail

```bash
# 1. Gerar App Password em https://myaccount.google.com/apppasswords
# 2. Editar .env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=seu-email@gmail.com
SMTP_PASSWORD=app-password-gerado
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# 3. Testar envio
docker compose exec rails \
  bundle exec rails runner \
  "Notifications::Mailer.mail_to_hello_user(User.first)"
```

### 5. SMTP com Sendgrid

```bash
# 1. Obter credenciais em https://sendgrid.com
# 2. Editar .env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=SG.sua-chave-aqui
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true

# 3. Reiniciar
docker compose restart rails sidekiq
```

### 6. WhatsApp Business API

```bash
# 1. Obter credenciais em https://www.whatsapp.com/business/
# 2. Na UI do Chatwoot: Settings → Inboxes → Add Channel → WhatsApp
# 3. Adicionar Business Account ID e Token
```

### 7. Integração Slack

```bash
# UI: Settings → Integrations → Slack
# 1. Criar app em https://api.slack.com/
# 2. Configurar Bot Token Scopes
# 3. Instalar em seu workspace
```

### 8. Integração Dialogflow

```bash
# 1. Criar agente em https://dialogflow.cloud.google.com/
# 2. Baixar JSON de credenciais
# 3. NA NA UI do Chatwoot: Settings → Integrations → Dialogflow
# 4. Upload do arquivo JSON
```

## 🔒 Segurança - Hardening

### Rate Limiting com Nginx

```nginx
# Adicionar em /etc/nginx/sites-available/chatwoot

limit_req_zone $binary_remote_addr zone=chatwoot_limit:10m rate=10r/s;

server {
    # ...
    
    location ~ ^/auth/ {
        limit_req zone=chatwoot_limit burst=5 nodelay;
        proxy_pass http://chatwoot;
    }
    
    location ~ ^/api/ {
        limit_req zone=chatwoot_limit burst=20 nodelay;
        proxy_pass http://chatwoot;
    }
}
```

### Firewall com UFW

```bash
# Ubuntu/Debian
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH (adaptar conforme necessário)
sudo ufw allow 22/tcp

# Permitir HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# MySQL se exposição for necessária (não recomendado para produção)
# sudo ufw allow from 10.0.0.0/8 to any port 5432

sudo ufw enable
sudo ufw status
```

### Fail2Ban

```bash
# Instalar
sudo apt-get install fail2ban

# Criar configuração customizada
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true

[nginx-http-auth]
enabled = true

[nginx-noscript]
enabled = true
EOF

# Iniciar
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Verificar banimentos
sudo fail2ban-client status sshd
```

## 📊 Monitoramento Avançado

### Integração Sentry

```bash
# 1. Criar conta em https://sentry.io
# 2. Editar .env
SENTRY_DSN=https://sua-key@sentry.io/xxx

# 3. Reiniciar
docker compose restart rails sidekiq
```

### Prometheus + Grafana

```yaml
# docker-compose.yml - adicionar serviço

prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus_data:/prometheus
  ports:
    - "127.0.0.1:9090:9090"

grafana:
  image: grafana/grafana
  volumes:
    - grafana_data:/var/lib/grafana
  ports:
    - "127.0.0.1:3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
```

### ELK Stack (Elasticsearch, Logstash, Kibana)

```bash
# Docker Compose servindo logs centralizados
# Útil para múltiplos servidores Chatwoot

docker-compose.yml - adicionar:
  elasticsearch:
  logstash:
  kibana:
```

## 🔄 Migração de Dados

### Backup Completo

```bash
# Criar backup manual
/usr/local/bin/backup-chatwoot.sh

# Listar backups
ls -lh /opt/chatwoot/backups/

# Fazer backup customizado
cd /opt/chatwoot
docker compose exec -T postgres pg_dump -U postgres chatwoot > backup_manuel.sql
tar -czf backup_completo.tar.gz .env backup_manuel.sql
```

### Restaurar de Backup

```bash
# 1. Parar serviços
docker compose down

# 2. Restaurar arquivo .env
tar -xzf /opt/chatwoot/backups/seu_backup.tar.gz -C /opt/chatwoot/

# 3. Restaurar banco de dados
docker compose up -d postgres redis
sleep 10
docker compose exec -T postgres psql -U postgres chatwoot < backup_manuel.sql

# 4. Iniciar tudo
docker compose up -d
```

### Migração para Novo Servidor

```bash
# No servidor antigo:
/usr/local/bin/backup-chatwoot.sh
scp /opt/chatwoot/backups/chatwoot_backup_*.tar.gz root@novo-server:/tmp/

# No novo servidor:
# 1. Executar setup_vps.sh (instalação limpa)
# 2. Parar serviços: docker compose down
# 3. Restaurar: tar -xzf /tmp/chatwoot_backup_*.tar.gz -C /opt/chatwoot/
# 4. Restaurar BD e reiniciar
```

## 🆘 Troubleshooting Avançado

### Container Rails não inicia

```bash
cd /opt/chatwoot

# Ver logs em tempo real
docker compose logs -f rails

# Executar comando manualmente
docker compose run --rm rails bundle exec rails db:migrate

# Acessar console Rails
docker compose run --rm rails bundle exec rails console
```

### Banco de dados corrompido

```bash
cd /opt/chatwoot

# Verificar integridade
docker compose exec postgres pg_dump -U postgres chatwoot > /tmp/teste_dump.sql

# Se falhar, tentar reparo
docker compose exec postgres pg_repair
```

### Redis cheio

```bash
cd /opt/chatwoot

# Limpar cache
docker compose exec redis redis-cli FLUSHALL

# Ver memória usada
docker compose exec redis redis-cli INFO memory

# Monitorar em tempo real
docker compose exec redis redis-cli MONITOR
```

### Espaço em disco cheio

```bash
# Verificar uso
du -sh /opt/chatwoot/*

# Limpar logs Docker
docker system prune -a --volumes -f

# Backup e deletar old backups
find /opt/chatwoot/backups -mtime +30 -delete
```

## 🐳 Docker Compose Variações

### Desenvolvimento Local

```yaml
# docker-compose.yml
version: '3'
services:
  rails:
    build: .
    volumes:
      - .:/app
    environment:
      - RAILS_ENV=development
    ports:
      - "3000:3000"
```

### Alta Disponibilidade (HA)

```yaml
# Usar múltiplas instâncias Rails por trás de load balancer
# Postgres com replicação
# Redis com Sentinel
# Nginx com upstream múltiplos
```

### Staging/QA

```bash
# docker-compose.staging.yml
docker compose -f docker-compose.staging.yml up -d
```

## 📞 Suporte e Recursos

- **Documentação**: https://www.chatwoot.com/help-center
- **GitHub**: https://github.com/chatwoot/chatwoot
- **Discord**: https://discord.gg/chatwoot
- **Issues**: https://github.com/chatwoot/chatwoot/issues
- **Forum**: https://www.chatwoot.com/community

---

**Última atualização**: Abril 2026 | **Versão**: 1.0
