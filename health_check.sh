#!/bin/bash

################################################################################
# Chatwoot Health Check e Monitoramento
# 
# Verifica saúde e status da instalação Chatwoot
#
# Uso: bash health_check.sh
################################################################################

CHATWOOT_DIR="${1:-/opt/chatwoot}"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((CHECKS_PASSED++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    ((CHECKS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    ((CHECKS_WARNING++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Chatwoot Health Check                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# Verificações do Sistema
# =============================================================================

echo -e "${BLUE}=== VERIFICAÇÕES DO SISTEMA ===${NC}"
echo ""

# Docker
if command -v docker &> /dev/null; then
    log_success "Docker instalado"
else
    log_error "Docker não instalado"
fi

# Docker Compose
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    log_success "Docker Compose instalado"
else
    log_warning "Docker Compose não encontrado"
fi

# Nginx
if systemctl is-active --quiet nginx; then
    log_success "Nginx está rodando"
else
    log_error "Nginx não está rodando"
fi

# Certbot
if command -v certbot &> /dev/null; then
    log_success "Certbot (Let's Encrypt) instalado"
else
    log_warning "Certbot não instalado"
fi

echo ""

# =============================================================================
# Verificações de Diretórios
# =============================================================================

echo -e "${BLUE}=== VERIFICAÇÕES DE DIRETÓRIOS ===${NC}"
echo ""

if [ -d "$CHATWOOT_DIR" ]; then
    log_success "Diretório Chatwoot existe: $CHATWOOT_DIR"
else
    log_error "Diretório Chatwoot não encontrado: $CHATWOOT_DIR"
    exit 1
fi

if [ -f "$CHATWOOT_DIR/docker-compose.yml" ]; then
    log_success "arquivo docker-compose.yml encontrado"
else
    log_error "arquivo docker-compose.yml não encontrado"
fi

if [ -f "$CHATWOOT_DIR/.env" ]; then
    log_success "arquivo .env encontrado"
    # Verificar permissões
    perms=$(stat -f%OLp "$CHATWOOT_DIR/.env" 2>/dev/null || stat -c %a "$CHATWOOT_DIR/.env" 2>/dev/null)
    if [ "$perms" = "600" ] || [ "$perms" = "640" ]; then
        log_success "Permissões de .env corretas"
    else
        log_warning "Permissões de .env são $perms (recomendado: 600)"
    fi
else
    log_error "arquivo .env não encontrado"
fi

echo ""

# =============================================================================
# Verificações de Containers Docker
# =============================================================================

echo -e "${BLUE}=== VERIFICAÇÕES DE CONTAINERS ===${NC}"
echo ""

cd "$CHATWOOT_DIR"

if ! docker info &> /dev/null; then
    log_error "Docker daemon não está rodando"
else
    log_success "Docker daemon está respondendo"
    
    # Verificar containers
    CONTAINERS=$(docker compose ps --quiet)
    
    if [ -z "$CONTAINERS" ]; then
        log_warning "Nenhum container está rodando"
    else
        log_success "Containers encontrados"
        echo ""
        
        # PostgreSQL
        if docker compose ps postgres | grep -q "Up"; then
            log_success "PostgreSQL está rodando"
        else
            log_error "PostgreSQL não está respondendo"
        fi
        
        # Redis
        if docker compose ps redis | grep -q "Up"; then
            log_success "Redis está rodando"
        else
            log_error "Redis não está respondendo"
        fi
        
        # Rails
        if docker compose ps rails | grep -q "Up"; then
            log_success "Rails está rodando"
        else
            log_error "Rails não está respondendo"
        fi
        
        # Sidekiq
        if docker compose ps sidekiq | grep -q "Up"; then
            log_success "Sidekiq está rodando"
        else
            log_error "Sidekiq não está respondendo"
        fi
    fi
fi

echo ""

# =============================================================================
# Verificações de Conectividade
# =============================================================================

echo -e "${BLUE}=== VERIFICAÇÕES DE CONECTIVIDADE ===${NC}"
echo ""

# Health Check local
if curl -sf http://127.0.0.1:3000/health_check &> /dev/null; then
    log_success "Rails respondendo em http://localhost:3000"
else
    log_warning "Rails não respondendo ou saúde degradada"
fi

# PostgreSQL
if docker compose exec -T postgres pg_isready -U postgres &> /dev/null 2>&1; then
    log_success "PostgreSQL respondendo"
    
    # Verificar tamanho do banco
    DB_SIZE=$(docker compose exec -T postgres psql -U postgres -d chatwoot -c "SELECT pg_size_pretty(pg_database_size('chatwoot'));" 2>/dev/null | tail -1 | xargs)
    log_info "Tamanho do banco de dados: $DB_SIZE"
else
    log_error "PostgreSQL não respondendo"
fi

# Redis
if docker compose exec -T redis redis-cli ping &> /dev/null 2>&1; then
    log_success "Redis respondendo"
else
    log_error "Redis não respondendo"
fi

echo ""

# =============================================================================
# Certificado SSL
# =============================================================================

echo -e "${BLUE}=== VERIFICAÇÕES DE SSL ===${NC}"
echo ""

CERT_PATH="/etc/letsencrypt/live"

# Encontrar certificate para o domínio
DOMAIN_CERT=$(ls "$CERT_PATH" 2>/dev/null | head -1)

if [ -n "$DOMAIN_CERT" ]; then
    CERT_FILE="$CERT_PATH/$DOMAIN_CERT/fullchain.pem"
    
    if [ -f "$CERT_FILE" ]; then
        EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_FILE" | cut -d= -f2)
        EXPIRY_DATE=$(date -d "$EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$EXPIRY" +%s 2>/dev/null)
        NOW=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRY_DATE - $NOW) / 86400 ))
        
        if [ "$DAYS_LEFT" -gt 30 ]; then
            log_success "Certificado SSL válido (expira em $DAYS_LEFT dias)"
        elif [ "$DAYS_LEFT" -gt 0 ]; then
            log_warning "Certificado SSL vai expirar em $DAYS_LEFT dias"
        else
            log_error "Certificado SSL expirado"
        fi
    else
        log_warning "Arquivo de certificado não encontrado"
    fi
else
    log_warning "Nenhum certificado Let's Encrypt encontrado"
fi

echo ""

# =============================================================================
# Logs Recentes
# =============================================================================

echo -e "${BLUE}=== ÚLTIMAS LINHAS DE LOG (RAILS) ===${NC}"
echo ""

if [ -d "$CHATWOOT_DIR" ]; then
    docker compose logs --tail 10 rails 2>/dev/null | tail -15 || log_warning "Não foi possível obter logs"
else
    log_warning "Diretório Chatwoot não acessível"
fi

echo ""

# =============================================================================
# Resumo
# =============================================================================

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  RESUMO DO HEALTH CHECK                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

TOTAL=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))

echo -e "${GREEN}Verificações passadas: $CHECKS_PASSED${NC}"
if [ $CHECKS_WARNING -gt 0 ]; then
    echo -e "${YELLOW}Avisos: $CHECKS_WARNING${NC}"
fi
if [ $CHECKS_FAILED -gt 0 ]; then
    echo -e "${RED}Falhas: $CHECKS_FAILED${NC}"
fi

echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Sistema está saudável!${NC}"
    echo ""
    
    # Obter domínio do .env
    if [ -f "$CHATWOOT_DIR/.env" ]; then
        DOMAIN=$(grep "FRONTEND_URL" "$CHATWOOT_DIR/.env" | cut -d= -f2 | sed 's|https://||; s|http://||')
        if [ -n "$DOMAIN" ]; then
            echo -e "Acesse: ${YELLOW}https://$DOMAIN${NC}"
        fi
    fi
    
    exit 0
else
    echo -e "${RED}✗ Sistema com problemas. Verifique acima.${NC}"
    echo ""
    echo "Dicas de troubleshooting:"
    echo "  - Ver logs:      docker compose -f $CHATWOOT_DIR/docker-compose.yml logs -f"
    echo "  - Reiniciar:     docker compose -f $CHATWOOT_DIR/docker-compose.yml restart"
    echo "  - Verificar rede: docker network inspect chatwoot_default"
    echo ""
    exit 1
fi
