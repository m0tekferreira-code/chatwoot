#!/bin/bash

################################################################################
# Chatwoot VPS Setup Script
# 
# Este script automatiza a instalação completa do Chatwoot em uma VPS
# Compatível com: Ubuntu 20.04, 22.04, 24.04
# 
# Uso: sudo bash setup_vps.sh
################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis globais
CHATWOOT_DIR="/opt/chatwoot"
NGINX_CONF="/etc/nginx/sites-available/chatwoot"
CERTBOT_EMAIL=""
DOMAIN=""
POSTGRES_PASSWORD=""
REDIS_PASSWORD=""
SECRET_KEY_BASE=""

################################################################################
# Funções Auxiliares
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script deve ser executado como root (sudo)"
        exit 1
    fi
}

generate_secret() {
    openssl rand -hex 32
}

validate_domain() {
    local domain=$1
    # Aceita: domínios, subdomínios e localhost
    # Formato: letras, números, hífens, pontos
    # Não pode começar/terminar com hífen ou ponto
    if [[ ! $domain =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?$ ]]; then
        return 1
    fi
    
    # Validação adicional: mínimo de caracteres
    if [ ${#domain} -lt 2 ]; then
        return 1
    fi
    
    return 0
}

read_input() {
    local prompt=$1
    local variable=$2
    local default=${3:-}
    
    if [ -z "$default" ]; then
        read -p "$(echo -e ${BLUE}$prompt${NC}): " input
    else
        read -p "$(echo -e ${BLUE}$prompt${NC}) [$default]: " input
        input=${input:-$default}
    fi
    
    eval "$variable='$input'"
}

################################################################################
# Verificações Iniciais
################################################################################

check_initial_requirements() {
    log_info "Verificando requisitos iniciais..."
    
    check_root
    
    # Detectar distribuição
    if [[ ! -f /etc/os-release ]]; then
        log_error "Não foi possível detectar a distribuição"
        exit 1
    fi
    
    source /etc/os-release
    
    if [[ ! "$ID" == "ubuntu" ]]; then
        log_warning "Este script é otimizado para Ubuntu. Continuando mesmo assim..."
    fi
    
    log_success "Tudo certo para começar"
}

################################################################################
# Configuração Interativa
################################################################################

configure_environment() {
    log_info "Configuração do Chatwoot"
    echo ""
    
    # URL/Domínio
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}URL de Instalação${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Exemplos válidos:"
    echo "  • chat.example.com          (domínio principal)"
    echo "  • support.example.com       (subdomínio simples)"
    echo "  • chat.suporte.example.com  (múltiplos subdomínios)"
    echo "  • localhost                 (teste local - não funciona com SSL)"
    echo ""
    
    while true; do
        read_input "Digite a URL/domínio para acessar o Chatwoot" "DOMAIN"
        if validate_domain "$DOMAIN"; then
            log_success "URL válida: $DOMAIN"
            echo ""
            break
        else
            log_error "URL inválida. Use apenas letras, números, hífens e pontos."
            echo ""
        fi
    done
    
    # Email para certificado SSL
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Certificado SSL${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read_input "Email para certificado Let's Encrypt (receber notificações de renovação)" "CERTBOT_EMAIL"
    echo ""
    
    # Senhas
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Gerando Configurações de Segurança${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    log_info "Gerando senhas seguras para PostgreSQL, Redis e Rails..."
    POSTGRES_PASSWORD=$(generate_secret)
    REDIS_PASSWORD=$(generate_secret)
    SECRET_KEY_BASE=$(generate_secret)
    
    log_success "Senhas geradas com sucesso (32 caracteres cada)"
    echo ""
    
    # Usuário admin
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Usuário Administrador${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Estas credenciais serão usadas para fazer login no Chatwoot"
    echo ""
    
    read_input "Email do administrador" "ADMIN_EMAIL"
    read_input "Nome do administrador (padrão: Admin)" "ADMIN_NAME" "Admin"
    
    echo ""
    read -sp "Senha do administrador (não será exibida): " ADMIN_PASSWORD
    echo ""
    read -sp "Confirme a senha do administrador: " ADMIN_PASSWORD_CONFIRM
    echo ""
    echo ""
    
    if [[ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]]; then
        log_error "Senhas não conferem"
        exit 1
    fi
    
    if [ ${#ADMIN_PASSWORD} -lt 6 ]; then
        log_error "Senha deve ter pelo menos 6 caracteres"
        exit 1
    fi
    
    log_success "Configurações validadas com sucesso"
    echo ""
}

################################################################################
# Atualização do Sistema
################################################################################

update_system() {
    log_info "Atualizando sistema..."
    apt-get update
    apt-get upgrade -y
    log_success "Sistema atualizado"
}

################################################################################
# Instalação do Docker
################################################################################

install_docker() {
    log_info "Verificando Docker..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker já está instalado"
        return
    fi
    
    log_info "Instalando Docker..."
    
    # Instalar dependências
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Adicionar key do Docker
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Adicionar repositório
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Iniciar Docker
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker instalado com sucesso"
}

################################################################################
# Instalação do Nginx
################################################################################

install_nginx() {
    log_info "Verificando Nginx..."
    
    if command -v nginx &> /dev/null; then
        log_success "Nginx já está instalado"
        return
    fi
    
    log_info "Instalando Nginx..."
    apt-get install -y nginx
    
    systemctl enable nginx
    systemctl start nginx
    
    log_success "Nginx instalado com sucesso"
}

################################################################################
# Instalação do Certbot (Let's Encrypt)
################################################################################

install_certbot() {
    log_info "Verificando Certbot..."
    
    if command -v certbot &> /dev/null; then
        log_success "Certbot já está instalado"
        return
    fi
    
    log_info "Instalando Certbot..."
    apt-get install -y certbot python3-certbot-nginx
    
    log_success "Certbot instalado com sucesso"
}

################################################################################
# Preparação de Diretórios
################################################################################

setup_directories() {
    log_info "Preparando diretórios..."
    
    mkdir -p "$CHATWOOT_DIR"
    cd "$CHATWOOT_DIR"
    
    log_success "Diretórios criados em $CHATWOOT_DIR"
}

################################################################################
# Download e Configuração do Docker Compose
################################################################################

setup_docker_compose() {
    log_info "Configurando Docker Compose..."
    
    cd "$CHATWOOT_DIR"
    
    # Baixar docker-compose.production.yaml
    curl -fsSL https://raw.githubusercontent.com/chatwoot/chatwoot/master/docker-compose.production.yaml -o docker-compose.yml
    
    log_success "docker-compose.yml baixado"
}

################################################################################
# Criação do arquivo .env
################################################################################

create_env_file() {
    log_info "Criando arquivo .env..."
    
    cat > "$CHATWOOT_DIR/.env" << EOF
# Chatwoot Environment Configuration
# Generated on $(date)

# Application
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker

# Database
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=chatwoot
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Redis
REDIS_URL=redis://:$REDIS_PASSWORD@redis:6379

# Rails
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=$SECRET_KEY_BASE

# Host Configuration
FRONTEND_URL=https://$DOMAIN
MAILER_SENDER_EMAIL=$ADMIN_EMAIL

# S3 Configuration (opcional)
# S3_BUCKET_NAME=
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# AWS_REGION=

# SMTP Configuration (opcional)
# SMTP_HOST=
# SMTP_PORT=
# SMTP_USERNAME=
# SMTP_PASSWORD=
# SMTP_AUTHENTICATION=
# SMTP_ENABLE_STARTTLS_AUTO=true

# Sentry (opcional, para monitoramento de erros)
# SENTRY_DSN=

# Debug (desativar em produção)
DEBUG=false
LOG_LEVEL=info

# Máximo de upload
MAX_FILE_SIZE=104857600

# Timezone
TIMEZONE=UTC

# Admin User (para seed inicial)
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_NAME=$ADMIN_NAME
ADMIN_PASSWORD=$ADMIN_PASSWORD
EOF

    chmod 600 "$CHATWOOT_DIR/.env"
    log_success "Arquivo .env criado"
}

################################################################################
# Configuração do Nginx
################################################################################

setup_nginx() {
    log_info "Configurando Nginx..."
    
    cat > "$NGINX_CONF" << 'EOF'
upstream chatwoot {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;
    
    # Redirecionar HTTP para HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name DOMAIN_PLACEHOLDER;

    # SSL (será preenchido pelo Certbot)
    ssl_certificate /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logs
    access_log /var/log/nginx/chatwoot_access.log;
    error_log /var/log/nginx/chatwoot_error.log;

    # Segurança
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Tamanho máximo de upload
    client_max_body_size 100M;

    # Proxy para Chatwoot
    location / {
        proxy_pass http://chatwoot;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }

    # WebSocket
    location /cable {
        proxy_pass http://chatwoot/cable;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

    # Substituir placeholder do domínio
    sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" "$NGINX_CONF"
    
    # Criar link para sites-enabled
    ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/chatwoot
    
    # Remover site padrão se existir
    rm -f /etc/nginx/sites-enabled/default
    
    # Testar configuração
    nginx -t
    
    log_success "Nginx configurado"
}

################################################################################
# Configuração do SSL
################################################################################

setup_ssl() {
    log_info "Configurando certificado SSL..."
    
    # Parar o Nginx temporariamente
    systemctl stop nginx
    
    # Executar Certbot
    certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email "$CERTBOT_EMAIL" \
        -d "$DOMAIN"
    
    # Reiniciar Nginx
    systemctl start nginx
    
    # Testar renovação automática
    certbot renew --dry-run
    
    log_success "Certificado SSL configurado"
}

################################################################################
# Inicialização dos Serviços Docker
################################################################################

start_services() {
    log_info "Iniciando serviços Docker..."
    
    cd "$CHATWOOT_DIR"
    
    # Fazer pull das imagens
    docker compose pull
    
    # Iniciar serviços
    docker compose up -d
    
    # Aguardar inicialização
    log_info "Aguardando inicialização do Chatwoot (isso pode levar alguns minutos)..."
    sleep 30
    
    log_success "Serviços iniciados"
}

################################################################################
# Seed do Banco de Dados
################################################################################

seed_database() {
    log_info "Inicializando banco de dados..."
    
    cd "$CHATWOOT_DIR"
    
    # Executar migrations
    docker compose exec -T rails bundle exec rails db:create
    docker compose exec -T rails bundle exec rails db:migrate
    
    log_success "Banco de dados inicializado"
}

################################################################################
# Validate Services
################################################################################

validate_services() {
    log_info "Validando serviços..."
    
    # Aguardar a aplicação ficar pronta
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -sf http://127.0.0.1:3000/health_check > /dev/null 2>&1; then
            log_success "Aplicação Chatwoot está respondendo"
            return 0
        fi
        
        attempt=$((attempt + 1))
        log_info "Tentativa $attempt de $max_attempts... aguardando aplicação"
        sleep 5
    done
    
    log_warning "Aplicação não respondeu no tempo esperado. Verifique os logs com:"
    log_warning "docker compose -f $CHATWOOT_DIR/docker-compose.yml logs"
}

################################################################################
# Configurar Renovação Automática de SSL
################################################################################

setup_ssl_renewal() {
    log_info "Configurando renovação automática de SSL..."
    
    # Criar script de renovação
    cat > /usr/local/bin/renewal-chatwoot.sh << 'EOF'
#!/bin/bash

CHATWOOT_DIR="/opt/chatwoot"
ERROR_LOG="/var/log/chatwoot_renewal_error.log"

# Renovar certificados
certbot renew --quiet

# Recarregar Nginx
systemctl reload nginx

# Fazer backup dos logs
echo "Renovação executada em $(date)" >> /var/log/chatwoot_renewal.log
EOF

    chmod +x /usr/local/bin/renewal-chatwoot.sh
    
    # Adicionar cron job
    (crontab -l 2>/dev/null | grep -v "renewal-chatwoot.sh"; echo "0 3 * * * /usr/local/bin/renewal-chatwoot.sh") | crontab -
    
    log_success "Renovação automática de SSL configurada"
}

################################################################################
# Criar Script de Backup
################################################################################

create_backup_script() {
    log_info "Criando script de backup..."
    
    cat > /usr/local/bin/backup-chatwoot.sh << 'EOF'
#!/bin/bash

CHATWOOT_DIR="/opt/chatwoot"
BACKUP_DIR="/opt/chatwoot/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/chatwoot_backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

# Fazer backup do banco de dados
docker compose -f "$CHATWOOT_DIR/docker-compose.yml" exec -T postgres pg_dump -U postgres chatwoot > "$BACKUP_DIR/db_$DATE.sql"

# Comprimir
tar -czf "$BACKUP_FILE" \
    "$CHATWOOT_DIR/.env" \
    "$BACKUP_DIR/db_$DATE.sql" \
    2>/dev/null

# Remover dump SQL
rm -f "$BACKUP_DIR/db_$DATE.sql"

# Manter apenas os últimos 7 backups
find "$BACKUP_DIR" -name "chatwoot_backup_*.tar.gz" -mtime +7 -delete

echo "Backup realizado: $BACKUP_FILE"
EOF

    chmod +x /usr/local/bin/backup-chatwoot.sh
    
    # Adicionar cron job para backup diário
    (crontab -l 2>/dev/null | grep -v "backup-chatwoot.sh"; echo "0 2 * * * /usr/local/bin/backup-chatwoot.sh") | crontab -
    
    log_success "Script de backup criado"
}

################################################################################
# Criar Script de Atualização
################################################################################

create_update_script() {
    log_info "Criando script de atualização..."
    
    cat > /usr/local/bin/update-chatwoot.sh << 'EOF'
#!/bin/bash

CHATWOOT_DIR="/opt/chatwoot"

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[✓] $1"
}

cd "$CHATWOOT_DIR"

log_info "Fazendo backup antes de atualizar..."
/usr/local/bin/backup-chatwoot.sh

log_info "Parando serviços..."
docker compose down

log_info "Atualizando imagens..."
docker compose pull

log_info "Iniciando serviços..."
docker compose up -d

log_info "Executando migrations..."
docker compose exec -T rails bundle exec rails db:migrate

log_success "Atualização concluída!"
EOF

    chmod +x /usr/local/bin/update-chatwoot.sh
    
    log_success "Script de atualização criado"
}

################################################################################
# Print Summary
################################################################################

print_summary() {
    echo ""
    echo -e "${GREEN}===============================================${NC}"
    echo -e "${GREEN}✓ Chatwoot instalado com sucesso!${NC}"
    echo -e "${GREEN}===============================================${NC}"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo -e "${BLUE}🌐 ACESSAR A APLICAÇÃO${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo ""
    echo -e "  URL: ${YELLOW}https://$DOMAIN${NC}"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo -e "${BLUE}👤 CREDENCIAIS DE LOGIN${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo ""
    echo -e "  Email: ${YELLOW}$ADMIN_EMAIL${NC}"
    echo -e "  Nome:  ${YELLOW}$ADMIN_NAME${NC}"
    echo -e "  Senha: ${YELLOW}(a que você definiu)${NC}"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo -e "${BLUE}📁 LOCALIZAÇÃO DOS ARQUIVOS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo ""
    echo -e "  Aplicação:  ${YELLOW}$CHATWOOT_DIR${NC}"
    echo -e "  Config:     ${YELLOW}$CHATWOOT_DIR/.env${NC}"
    echo -e "  Nginx:      ${YELLOW}/etc/nginx/sites-available/chatwoot${NC}"
    echo -e "  Backups:    ${YELLOW}$CHATWOOT_DIR/backups/${NC}"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo -e "${BLUE}⚙️  CERTIFICADO SSL${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo ""
    echo -e "  Domínio:   ${YELLOW}$DOMAIN${NC}"
    echo -e "  Email:     ${YELLOW}$CERTBOT_EMAIL${NC}"
    echo -e "  Status:    ${GREEN}✓ Ativo (renovação automática)${NC}"
    echo -e "  Caminho:   ${YELLOW}/etc/letsencrypt/live/$DOMAIN/${NC}"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo -e "${BLUE}🛠️  COMANDOS ÚTEIS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo ""
    echo -e "  Ver logs:                 ${YELLOW}docker compose -f $CHATWOOT_DIR/docker-compose.yml logs -f rails${NC}"
    echo -e "  Verificar saúde:          ${YELLOW}bash $CHATWOOT_DIR/health_check.sh${NC}"
    echo -e "  Parar serviços:           ${YELLOW}cd $CHATWOOT_DIR && docker compose down${NC}"
    echo -e "  Iniciar serviços:         ${YELLOW}cd $CHATWOOT_DIR && docker compose up -d${NC}"
    echo -e "  Fazer backup:             ${YELLOW}/usr/local/bin/backup-chatwoot.sh${NC}"
    echo -e "  Atualizar Chatwoot:       ${YELLOW}/usr/local/bin/update-chatwoot.sh${NC}"
    echo ""
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo -e "${BLUE}📋 PRÓXIMAS AÇÕES RECOMENDADAS${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo ""
    echo -e "  1️⃣  Acesse: ${YELLOW}https://$DOMAIN${NC}"
    echo -e "  2️⃣  Faça login com email/senha"
    echo -e "  3️⃣  Configure canais (WhatsApp, Email, Facebook, etc)"
    echo -e "  4️⃣  Adicione agentes à sua equipe"
    echo -e "  5️⃣  Configure SMTP para envio de emails"
    echo ""
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANTES${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━███${NC}"
    echo ""
    echo -e "  • Guarde suas credenciais em local seguro"
    echo -e "  • Arquivo .env contém dados sensíveis (não compartilhe)"
    echo -e "  • Backup automático executado diariamente às 02:00"
    echo -e "  • SSL é renovado automaticamente (verificar em 30 dias)"
    echo -e "  • Para desabilitar features, edite .env e reinicie"
    echo ""
    
    echo -e "${BLUE}📚 DOCUMENTAÇÃO${NC}"
    echo -e "  Guia completo:        ${YELLOW}$CHATWOOT_DIR/SETUP_VPS.md${NC}"
    echo -e "  Configurações avançadas: ${YELLOW}$CHATWOOT_DIR/ADVANCED_CONFIG.md${NC}"
    echo -e "  Referência rápida:    ${YELLOW}$CHATWOOT_DIR/QUICK_START.sh${NC}"
    echo ""
    echo -e "${GREEN}✓ Instalação concluída com sucesso!${NC}"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║    Chatwoot VPS Setup Script          ║"
    echo "║    Instalação Automática              ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    check_initial_requirements
    configure_environment
    
    echo ""
    log_info "Iniciando processo de instalação..."
    echo ""
    
    update_system
    install_docker
    install_nginx
    install_certbot
    setup_directories
    setup_docker_compose
    create_env_file
    setup_ssl
    setup_nginx
    setup_ssl_renewal
    create_backup_script
    create_update_script
    start_services
    seed_database
    validate_services
    
    print_summary
}

# Executar main
main
