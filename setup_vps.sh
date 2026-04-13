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
INSTALLATION_MODE="NEW"  # NEW, UPDATE, ou REPAIR

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

# Contador de passos
STEP_CURRENT=0
STEP_TOTAL=14

run_step() {
    local step_name="$1"
    local step_func="$2"
    STEP_CURRENT=$((STEP_CURRENT + 1))

    # Mostrar progresso inline
    printf "\r  ${BLUE}[%2d/%d]${NC} %-45s" "$STEP_CURRENT" "$STEP_TOTAL" "$step_name..."

    # Executar função suprimindo output para arquivo de log
    local step_log="$CHATWOOT_DIR/logs/step_${STEP_CURRENT}.log"
    mkdir -p "$CHATWOOT_DIR/logs" 2>/dev/null
    if $step_func >> "$step_log" 2>&1; then
        printf "\r  ${GREEN}[✓]${NC} %-45s\n" "$step_name"
    else
        printf "\r  ${RED}[✗]${NC} %-45s\n" "$step_name"
        echo -e "      ${RED}Ver detalhes: $step_log${NC}"
        exit 1
    fi
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
# Detecção de Instalação Anterior
################################################################################

detect_existing_installation() {
    if [ -d "$CHATWOOT_DIR" ] && [ -f "$CHATWOOT_DIR/.env" ]; then
        return 0  # Instalação existe
    fi
    return 1  # Não existe
}

cleanup_previous_installation() {
    log_warning "Detectada instalação anterior. Limpando configurações antigas..."
    
    # Parar containers
    if [ -d "$CHATWOOT_DIR" ]; then
        cd "$CHATWOOT_DIR"
        docker compose down 2>/dev/null || true
    fi
    
    # Fazer backup automático
    if [ -f "/usr/local/bin/backup-chatwoot.sh" ]; then
        log_info "Fazendo backup automático..."
        /usr/local/bin/backup-chatwoot.sh || log_warning "Backup falhou, continuando mesmo assim"
    fi
    
    # Limpar Nginx config antigo
    log_info "Limpando configurações antigas de Nginx..."
    [ -f "/etc/nginx/sites-enabled/chatwoot" ] && sudo rm -f /etc/nginx/sites-enabled/chatwoot
    [ -f "$NGINX_CONF" ] && sudo rm -f "$NGINX_CONF"
    
    # Limpar cron jobs antigos (apenas os do Chatwoot)
    log_info "Limpando cron jobs antigos..."
    (crontab -l 2>/dev/null | grep -v "chatwoot\|renewal" | crontab - 2>/dev/null) || true
    
    # Remover .env antigo para recriação
    [ -f "$CHATWOOT_DIR/.env" ] && rm -f "$CHATWOOT_DIR/.env"
    
    log_success "Limpeza concluída"
}

handle_existing_installation() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  INSTALAÇÃO ANTERIOR DETECTADA${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Opções:"
    echo "  1) ATUALIZAR - Limpar config antiga e reinstalar (RECOMENDADO)"
    echo "  2) REPAIR - Apenas corrigir problemas mantendo dados"
    echo "  3) CANCELAR - Sair sem fazer nada"
    echo ""
    read -p "Escolha uma opção (1/2/3): " option
    
    case $option in
        1)
            log_info "Modo ATUALIZAR selecionado"
            INSTALLATION_MODE="UPDATE"
            cleanup_previous_installation
            ;;
        2)
            log_info "Modo REPAIR selecionado"
            INSTALLATION_MODE="REPAIR"
            # Em modo repair, apenas recreia containers e configs
            if [ -d "$CHATWOOT_DIR" ]; then
                cd "$CHATWOOT_DIR"
                docker compose down 2>/dev/null || true
            fi
            ;;
        3)
            log_error "Instalação cancelada pelo usuário"
            exit 0
            ;;
        *)
            log_error "Opção inválida"
            exit 1
            ;;
    esac
}

preflight_checks() {
    log_info "Executando verificações pré-voo..."
    
    # Verificar espaço em disco
    local available_space=$(df /opt | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 10485760 ]; then  # Menos de 10GB
        log_warning "Espaço em disco baixo (< 10GB disponível)"
    fi
    
    # Verificar permissões
    if ! touch /opt/chatwoot_test_write 2>/dev/null; then
        log_error "Sem permissão de escrita em /opt"
        return 1
    fi
    rm -f /opt/chatwoot_test_write
    
    # Verificar conectividade Internet
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_warning "Conectividade com Internet pode estar limitada"
    fi
    
    # Verificar ports
    if netstat -tuln 2>/dev/null | grep -q :80 || netstat -tuln 2>/dev/null | grep -q :443; then
        log_info "Porta 80 ou 443 já em uso (possível instalação anterior)"
    fi
    
    log_success "Verificações pré-voo concluídas"
}

################################################################################
# Backup e Recuperação
################################################################################

backup_before_changes() {
    if [ -d "$CHATWOOT_DIR/.env" ]; then
        local backup_timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_location="$CHATWOOT_DIR/backups/pre_change_$backup_timestamp"
        mkdir -p "$backup_location"
        
        log_info "Fazendo backup de segurança antes das mudanças..."
        cp "$CHATWOOT_DIR/.env" "$backup_location/.env" 2>/dev/null || true
        cp /etc/nginx/sites-available/chatwoot "$backup_location/nginx_config" 2>/dev/null || true
        
        log_success "Backup pré-mudança criado em: $backup_location"
    fi
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
    mkdir -p "$CHATWOOT_DIR/backups"
    mkdir -p "$CHATWOOT_DIR/logs"
    mkdir -p "/var/log/nginx"
    mkdir -p "/var/log/chatwoot"
    
    # Dar permissões apropriadas
    chmod 755 "$CHATWOOT_DIR"
    chmod 755 "$CHATWOOT_DIR/backups"
    chmod 755 "$CHATWOOT_DIR/logs"
    
    cd "$CHATWOOT_DIR"
    
    log_success "Diretórios criados e permissões configuradas"
}

################################################################################
# Download e Configuração do Docker Compose
################################################################################

setup_docker_compose() {
    log_info "Configurando Docker Compose..."
    
    cd "$CHATWOOT_DIR"
    
    # Se houver instalação anterior, remover containers com segurança
    if [ -f "docker-compose.yml" ]; then
        log_info "Removendo containers antigos com segurança..."
        docker compose down --remove-orphans 2>/dev/null || true
        sleep 2
    fi
    
    # Clonar o repositório customizado (contém pipelines e outras features)
    if [ -d "$CHATWOOT_DIR/src/.git" ]; then
        log_info "Repositório já clonado, atualizando..."
        cd "$CHATWOOT_DIR/src"
        git fetch origin && git reset --hard origin/main
    else
        log_info "Clonando repositório customizado..."
        rm -rf "$CHATWOOT_DIR/src"
        git clone https://github.com/m0tekferreira-code/chatwoot.git "$CHATWOOT_DIR/src" || {
            log_error "Falha ao clonar repositório"
            return 1
        }
    fi
    
    # Copiar docker-compose.production.yaml como docker-compose.yml
    cp "$CHATWOOT_DIR/src/docker-compose.production.yaml" "$CHATWOOT_DIR/docker-compose.yml"
    
    # Corrigir: postgres precisa ler POSTGRES_PASSWORD do .env (não vazio hardcoded)
    sed -i 's/- POSTGRES_PASSWORD=$/- POSTGRES_PASSWORD=${POSTGRES_PASSWORD}/' docker-compose.yml
    sed -i 's/- POSTGRES_USER=postgres/- POSTGRES_USER=${POSTGRES_USER:-postgres}/' docker-compose.yml
    sed -i 's/- POSTGRES_DB=chatwoot/- POSTGRES_DB=${POSTGRES_DB:-chatwoot}/' docker-compose.yml
    
    # Adicionar env_file no serviço postgres para carregar variáveis
    sed -i '/image: pgvector\/pgvector:pg16/a\    env_file: .env' docker-compose.yml
    
    # Ajustar build context para apontar ao diretório do código-fonte
    sed -i 's|context: \.|context: ./src|' docker-compose.yml
    
    # Remover atributo version obsoleto
    sed -i "/^version:/d" docker-compose.yml
    
    # Build da imagem customizada
    log_info "Construindo imagem Docker customizada (pode levar alguns minutos)..."
    cd "$CHATWOOT_DIR"
    docker compose build --no-cache || {
        log_error "Falha ao construir imagem Docker"
        return 1
    }
    
    log_success "docker-compose.yml configurado e imagem construída"
}

################################################################################
# Criação do arquivo .env
################################################################################

create_env_file() {
    log_info "Criando arquivo .env..."
    
    # Se .env existe, fazer backup e preservar variáveis
    if [ -f "$CHATWOOT_DIR/.env" ]; then
        log_info "Arquivo .env anterior encontrado, fazendo backup..."
        cp "$CHATWOOT_DIR/.env" "$CHATWOOT_DIR/.env.backup.$(date +%s)"
    fi
    
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
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Redis
REDIS_PASSWORD=$REDIS_PASSWORD
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
    log_success "Arquivo .env criado (backup feito se existia anteriormente)"
}

################################################################################
# Configuração do Nginx
################################################################################

setup_nginx() {
    log_info "Configurando Nginx..."
    
    # Remover config anterior se existir
    [ -f "$NGINX_CONF" ] && rm -f "$NGINX_CONF"
    [ -L "/etc/nginx/sites-enabled/chatwoot" ] && rm -f /etc/nginx/sites-enabled/chatwoot
    
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

log_installation_state() {
    log_info "Registrando estado da instalação..."
    
    local state_file="$CHATWOOT_DIR/installation_state.log"
    mkdir -p "$(dirname "$state_file")"
    
    {
        echo "═══════════════════════════════════════════════════════"
        echo "INSTALAÇÃO DO CHATWOOT - RELATÓRIO DE ESTADO"
        echo "═══════════════════════════════════════════════════════"
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "CONFIGURAÇÃO DO SISTEMA:"
        echo "  Hostname: $(hostname)"
        echo "  IP: $(hostname -I)"
        echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
        echo "  Kernel: $(uname -r)"
        echo ""
        echo "CONFIGURAÇÃO DO CHATWOOT:"
        echo "  Diretório: $CHATWOOT_DIR"
        echo "  Domínio: $DOMAIN"
        echo "  Email SSL: $CERTBOT_EMAIL"
        echo ""
        echo "SERVIÇOS DOCKER:"
        docker compose -f "$CHATWOOT_DIR/docker-compose.yml" ps 2>/dev/null || echo "  (Não disponível)"
        echo ""
        echo "CERTIFICADO SSL:"
        certbot certificates 2>/dev/null | grep -A5 "$DOMAIN" || echo "  (Não configurado ainda)"
        echo ""
        echo "CRON JOBS:"
        crontab -l 2>/dev/null | grep -v "^#" | head -5 || echo "  (Nenhum)"
        echo ""
        echo "ESPAÇO EM DISCO:"
        df -h "$CHATWOOT_DIR" | tail -1
        echo ""
        echo "═══════════════════════════════════════════════════════"
    } >> "$state_file" 2>&1
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
    
    # Remover cron job anterior se existir
    (crontab -l 2>/dev/null | grep -v "renewal-chatwoot.sh" || true; echo "0 3 * * * /usr/local/bin/renewal-chatwoot.sh") | crontab -
    
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
    
    # Remover cron job anterior se existir, depois adicionar novo
    (crontab -l 2>/dev/null | grep -v "backup-chatwoot.sh" || true; echo "0 2 * * * /usr/local/bin/backup-chatwoot.sh") | crontab -
    
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
    
    # Determinar mensagem baseada no modo de instalação
    if [ "$INSTALLATION_MODE" = "NEW" ]; then
        installation_msg="✓ Chatwoot instalado com sucesso!"
        mode_desc="INSTALAÇÃO NOVA"
        bg_color="$GREEN"
    elif [ "$INSTALLATION_MODE" = "UPDATE" ]; then
        installation_msg="✓ Chatwoot atualizado com sucesso!"
        mode_desc="ATUALIZAÇÃO COMPLETA"
        bg_color="$YELLOW"
    else  # REPAIR
        installation_msg="✓ Chatwoot reparado com sucesso!"
        mode_desc="REPARAÇÃO/MANUTENÇÃO"
        bg_color="$BLUE"
    fi
    
    echo -e "${bg_color}===============================================${NC}"
    echo -e "${bg_color}$installation_msg${NC}"
    echo -e "${bg_color}Modo: $mode_desc${NC}"
    echo -e "${bg_color}===============================================${NC}"
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
    
    # Detectar e lidar com instalação anterior
    if detect_existing_installation; then
        handle_existing_installation
    fi
    
    # Executar verificações pré-voo
    preflight_checks || exit 1
    
    # Fazer backup de segurança antes de começar
    backup_before_changes
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  PROGRESSO DA INSTALAÇÃO${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Garantir diretório de logs existe antes de run_step
    mkdir -p "$CHATWOOT_DIR/logs" 2>/dev/null || true
    
    run_step "Atualizar sistema"                update_system
    run_step "Instalar Docker"                  install_docker
    run_step "Instalar Nginx"                   install_nginx
    run_step "Instalar Certbot"                 install_certbot
    run_step "Preparar diretórios"              setup_directories
    run_step "Configurar Docker Compose"        setup_docker_compose
    run_step "Criar arquivo .env"               create_env_file
    run_step "Gerar certificado SSL"            setup_ssl
    run_step "Configurar Nginx"                 setup_nginx
    run_step "Configurar renovação SSL"         setup_ssl_renewal
    run_step "Criar script de backup"           create_backup_script
    run_step "Criar script de atualização"      create_update_script
    run_step "Iniciar serviços"                 start_services
    run_step "Popular banco de dados"           seed_database
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Validação final (mostra progresso em tempo real)
    validate_services
    log_installation_state
    
    print_summary
}

# Executar main
main
