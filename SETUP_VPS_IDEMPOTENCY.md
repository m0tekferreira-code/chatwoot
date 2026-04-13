# Melhorias de Idempotência no Setup VPS

## 📋 Resumo das Mudanças

O script `setup_vps.sh` foi totalmente reformulado para ser **totalmente idempotente** (seguro para rodar múltiplas vezes) com limpeza automática de instalações anteriores. Agora é um **serviço completo de produção**.

---

## ✨ Principais Melhorias Implementadas

### 1. **Detecção Automática de Instalação Anterior**
```bash
detect_existing_installation()  # Verifica se /opt/chatwoot/.env existe
handle_existing_installation()   # Menu para escolher ação
```

**O que acontece:**
- Se detectar instalação anterior, mostra 3 opções:
  - **1) ATUALIZAR** - Limpa tudo e reinstala (recomendado)
  - **2) REPAIR** - Apenas corrige problemas mantendo dados
  - **3) CANCELAR** - Sai sem fazer nada

### 2. **Limpeza Segura de Configuração Anterior**
```bash
cleanup_previous_installation()  # Remove configs antigas com segurança
```

**O que limpa:**
- Containers Docker antigos (com segurança: `docker compose down`)
- Configurações Nginx antigas
- Cron jobs antigos (renewal, backup)
- Arquivo .env para recriação

### 3. **Verificações Pré-Voo (Preflight Checks)**
```bash
preflight_checks()  # Executa antes de qualquer mudança
```

**Verifica:**
- ✓ Espaço em disco (< 10GB = aviso)
- ✓ Permissões de escrita em `/opt`
- ✓ Conectividade com Internet
- ✓ Portas 80/443 disponíveis

### 4. **Backup Automático Antes de Mudanças**
```bash
backup_before_changes()  # Cria backup pré-instalação
```

**Backup contém:**
- `.env` anterior
- Configuração Nginx anterior
- Local: `/opt/chatwoot/backups/pre_change_TIMESTAMP/`

### 5. **Prevenção de Cron Jobs Duplicados**
Melhorado em:
- `setup_ssl_renewal()` - Remove entrada antiga antes de adicionar
- `create_backup_script()` - Remove entrada antiga antes de adicionar

**Padrão usado:**
```bash
(crontab -l 2>/dev/null | grep -v "renewal-chatwoot.sh" || true; \
 echo "0 3 * * * /usr/local/bin/renewal-chatwoot.sh") | crontab -
```

### 6. **Remoção de Configs Nginx Antigas**
```bash
setup_nginx()  # Agora remove arquivo antigo antes de criar novo
```

**Ordem correta agora:**
1. Remove `/etc/nginx/sites-available/chatwoot` se existir
2. Remove symlink `/etc/nginx/sites-enabled/chatwoot` se existir
3. Cria novo arquivo
4. Cria novo symlink

### 7. **Gerenciamento Seguro de Containers**
```bash
setup_docker_compose()  # Agora remove containers em modo seguro
```

**O que faz:**
```bash
if [ -f "docker-compose.yml" ]; then
    log_info "Removendo containers antigos com segurança..."
    docker compose down --remove-orphans 2>/dev/null || true
    sleep 2
fi
```

### 8. **Preservação de Dados Sensíveis**
```bash
create_env_file()  # Faz backup de .env anterior antes de recriar
```

**Backup salvo em:**
- `/opt/chatwoot/.env.backup.TIMESTAMP`

### 9. **Diretórios com Permissões Corretas**
```bash
setup_directories()  # Cria todos os subdirs necessários
```

**Cria:**
- `/opt/chatwoot`
- `/opt/chatwoot/backups`
- `/opt/chatwoot/logs`
- `/var/log/nginx`
- `/var/log/chatwoot`

**Permissões:** 755 para todos

### 10. **Rastreamento de Modo de Execução**
Nova variável global:
```bash
INSTALLATION_MODE="NEW"  # NEW, UPDATE, ou REPAIR
```

**Usado para:**
- Definir mensagens de sucesso específicas
- Rastrear tipo de operação no log
- Diferente saída visual no sumário

### 11. **Registro de Estado da Instalação**
```bash
log_installation_state()  # Nova função no final do setup
```

**Salva em:** `/opt/chatwoot/installation_state.log`

**Contém:**
```
INSTALAÇÃO DO CHATWOOT - RELATÓRIO DE ESTADO
Timestamp: 2024-XX-XX HH:MM:SS

CONFIGURAÇÃO DO SISTEMA:
  Hostname: ...
  IP: ...
  OS: ...
  Kernel: ...

CONFIGURAÇÃO DO CHATWOOT:
  Diretório: /opt/chatwoot
  Domínio: chat.praxisis.com.br
  Email SSL: admin@example.com

SERVIÇOS DOCKER:
  [Lista de containers]

CERTIFICADO SSL:
  [Status do certificado]

CRON JOBS:
  [Jobs configurados]

ESPAÇO EM DISCO:
  [Espaço disponível]
```

### 12. **Sumário Melhorado com Modo de Instalação**
```bash
print_summary()  # Agora mostra qual modo foi usado
```

**Exibe diferentes mensagens:**
- **INSTALAÇÃO NOVA:** "✓ Chatwoot instalado com sucesso!"
- **ATUALIZAÇÃO:** "✓ Chatwoot atualizado com sucesso!"
- **REPARAÇÃO:** "✓ Chatwoot reparado com sucesso!"

---

## 🔄 Fluxo de Execução Agora

```
┌─ INÍCIO
│
├─ check_initial_requirements (root, OS)
├─ configure_environment (inputs do usuário)
│
├─ detect_existing_installation
│  └─ se SIM → handle_existing_installation (menu: UPDATE/REPAIR/CANCEL)
│  └─ se NÃO → continua (INSTALLATION_MODE = NEW)
│
├─ preflight_checks (espaço, permissões, conectividade)
├─ backup_before_changes (cria backup pré-mudança)
│
├─ update_system
├─ install_docker
├─ install_nginx
├─ install_certbot
├─ setup_directories (cria dirs com permissões)
├─ setup_docker_compose (remove containers antigos, download novo)
├─ create_env_file (backup .env antigo se existir)
├─ setup_ssl (SSL do Let's Encrypt)
├─ setup_nginx (remove config antigo, cria nova)
├─ setup_ssl_renewal (remove cron antigo, adiciona novo)
├─ create_backup_script (remove cron antigo, adiciona novo)
├─ create_update_script
├─ start_services
├─ seed_database
├─ validate_services (aguarda aplicação ficar pronta)
├─ log_installation_state (salva relatório)
│
├─ print_summary (mostra sucesso + modo)
│
└─ FIM
```

---

## 🧪 Testando Idempotência

Você pode rodar o script várias vezes com segurança:

**Primeira execução (instalação nova):**
```bash
sudo bash setup_vps.sh
# Escolhe ATUALIZAR (limpa, instala do zero)
```

**Segunda execução (verificar se é seguro):**
```bash
sudo bash setup_vps.sh
# Escolhe REPAIR (mantém dados, corrige problemas)
```

**Terceira execução (atualizar tudo):**
```bash
sudo bash setup_vps.sh  
# Escolhe ATUALIZAR (limpa configs, mantém dados em backups)
```

**Resultados esperados:**
- ✓ Sem erro sem importar quantas vezes
- ✓ Dados preservados em backups
- ✓ Cada execução registra em `installation_state.log`
- ✓ Cron jobs não duplicam
- ✓ Configs Nginx não sobrescrevem mal

---

## 📁 Arquivos de Backup e Logs

Após execução:

```
/opt/chatwoot/
├── .env (configuração atual)
├── .env.backup.1234567890 (backup automático)
├── docker-compose.yml
├── installation_state.log (relatório desta execução)
├── backups/
│   ├── pre_change_20240115_143022/ (backup pré-mudança)
│   │   ├── .env
│   │   └── nginx_config
│   ├── chatwoot_backup_20240115_143022.tar.gz (backup diário)
│   └── ... (backups antigos, mantém 7 dias)
└── logs/
    └── ... (logs da aplicação)

/var/log/
├── nginx/
│   ├── chatwoot_access.log
│   └── chatwoot_error.log
└── chatwoot/
    └── ... (logs da aplicação)
```

---

## 🛡️ Segurança

**Antes de qualquer mudança destruidora, o script:**
1. ✓ Faz backup de .env
2. ✓ Faz backup da config Nginx
3. ✓ Para containers com `docker compose down`
4. ✓ Aguarda 2 segundos para garantir parada
5. ✓ Cria pasta de backup pré-mudança com timestamp

**Em caso de falha:**
- Todos os arquivos originais estão em `/opt/chatwoot/backups/`
- A pasta `/opt/chatwoot/backups/pre_change_*` tem tudo antes da execução
- Restaurar é simples: copiar de volta

---

## 🎯 Uso em Produção

Este script agora é **seguro para produção** porque:

✓ **Idempotente**: Seguro rodar múltiplas vezes
✓ **Smart Detection**: Detecta estado anterior automaticamente
✓ **Safe Cleanup**: Remove configs antigas sem perder dados
✓ **Backup First**: Sempre faz backup antes de mudanças
✓ **No Duplicates**: Cron jobs e configs não duplicam
✓ **Logged**: Registra cada execução em arquivo
✓ **Mode Aware**: Diferencia INSTALAÇÃO/ATUALIZAÇÃO/REPARAÇÃO

---

## 🚀 Próximas Execuções

Se o script falhar ou você quiser rodar novamente:

```bash
# Com segurança total:
sudo bash setup_vps.sh

# Escolha:
# 1) ATUALIZAR (recomendado se teve erro)
# 2) REPAIR (se só quer corrigir)
# 3) CANCELAR (se quer investigar antes)
```

Tudo vai funcionar sem duplicar ou perder dados!

---

## 📝 Variáveis de Log

O arquivo `installation_state.log` permite rastrear:
- Quando foi instalado/atualizado
- Qual domínio está configurado
- Espaço em disco
- Status dos serviços Docker
- Certificado SSL ativo/inativo
- Cron jobs configurados

Use para auditoria e troubleshooting.

---

## ✅ Checklist Final

- [x] Detecção de instalação anterior
- [x] Menu de opções (UPDATE/REPAIR/CANCEL)
- [x] Limpeza segura de configs antigas
- [x] Verificações pré-voo
- [x] Backup automático antes de mudanças
- [x] Prevenção de cron duplicados
- [x] Remoção de Nginx configs antigas
- [x] Gerenciamento seguro de containers
- [x] Preservação de .env
- [x] Permissões corretas nos diretórios
- [x] Rastreamento de modo (NEW/UPDATE/REPAIR)
- [x] Registro de estado da instalação
- [x] Sumário com modo de execução
- [x] Script totalmente idempotente
