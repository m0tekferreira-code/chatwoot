#!/bin/bash

################################################################################
# Chatwoot VPS Setup Helper - Linux/macOS
# 
# Facilita o upload e execução do script setup_vps.sh em uma VPS remota
#
# Uso: bash deploy.sh
################################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Chatwoot VPS Deploy Helper            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar se SSH está disponível
if ! command -v ssh &> /dev/null; then
    echo -e "${RED}[✗] SSH não encontrado. Instale OpenSSH.${NC}"
    exit 1
fi

# Verificar se SCP está disponível
if ! command -v scp &> /dev/null; then
    echo -e "${RED}[✗] SCP não encontrado. Instale OpenSSH.${NC}"
    exit 1
fi

# Verificar se o script existe
if [ ! -f "./setup_vps.sh" ]; then
    echo -e "${RED}[✗] setup_vps.sh não encontrado no diretório atual${NC}"
    exit 1
fi

# Perguntar dados do servidor
echo -e "${YELLOW}Digite os dados da sua VPS:${NC}"
read -p "Host/IP do servidor: " SERVER_HOST
read -p "Usuário SSH (padrão: root): " SERVER_USER
SERVER_USER=${SERVER_USER:-root}
read -p "Porta SSH (padrão: 22): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-22}

# Construir variável de conexão
SERVER_CONNECTION="$SERVER_USER@$SERVER_HOST"
if [ "$SERVER_PORT" != "22" ]; then
    SERVER_CONNECTION="-P $SERVER_PORT $SERVER_CONNECTION"
fi

echo ""
echo -e "${BLUE}Testando conexão SSH...${NC}"

if ssh -p ${SERVER_PORT:-22} $SERVER_USER@$SERVER_HOST "echo 'OK'" &> /dev/null; then
    echo -e "${GREEN}[✓] Conexão SSH estabelecida${NC}"
else
    echo -e "${RED}[✗] Não foi possível conectar ao servidor${NC}"
    echo -e "${YELLOW}Verifique:${NC}"
    echo "  - Host/IP está correto"
    echo "  - Poder SSH está funcionando"
    echo "  - Chave SSH está configurada (se usar autenticação por chave)"
    exit 1
fi

echo ""
echo -e "${BLUE}Enviando script para o servidor...${NC}"

# Enviar arquivo
if scp -P ${SERVER_PORT:-22} ./setup_vps.sh $SERVER_USER@$SERVER_HOST:/tmp/setup_vps.sh 2>&1; then
    echo -e "${GREEN}[✓] Script enviado com sucesso${NC}"
else
    echo -e "${RED}[✗] Erro ao enviar script${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Deseja executar o script agora? (s/n)${NC}"
read -p "Resposta: " RUN_NOW

if [[ "$RUN_NOW" == "s" || "$RUN_NOW" == "S" ]]; then
    echo ""
    echo -e "${BLUE}Conectando ao servidor para executar o script...${NC}"
    echo ""
    
    ssh -p ${SERVER_PORT:-22} $SERVER_USER@$SERVER_HOST "bash /tmp/setup_vps.sh"
    
    echo ""
    echo -e "${GREEN}[✓] Instalação concluída!${NC}"
else
    echo ""
    echo -e "${YELLOW}Para executar o script manualmente:${NC}"
    echo "  ssh -p ${SERVER_PORT:-22} $SERVER_USER@$SERVER_HOST 'bash /tmp/setup_vps.sh'"
fi

echo ""
