#!/bin/bash

# 🚀 CHATWOOT VPS DEPLOYMENT - QUICK START

# ═══════════════════════════════════════════════════════════════════════════
# 1. PRIMEIRA INSTALAÇÃO (Linux/macOS)
# ═══════════════════════════════════════════════════════════════════════════

# Opção A: Upload com deploy helper
chmod +x deploy.sh
bash deploy.sh

# Opção B: Direct via SSH  
ssh root@seu-servidor.com 'bash -s' < setup_vps.sh

# Opção C: Windows (PowerShell)
.\deploy.ps1

# ═══════════════════════════════════════════════════════════════════════════
# 2. ACESSO APÓS INSTALAÇÃO
# ═══════════════════════════════════════════════════════════════════════════

# URL: https://seu-dominio.com
# Email: seu-email-admin@domain.com
# Senha: (a que você definiu no setup)

# ═══════════════════════════════════════════════════════════════════════════
# 3. COMANDOS DO DIA-A-DIA
# ═══════════════════════════════════════════════════════════════════════════

# Ver status
docker compose -f /opt/chatwoot/docker-compose.yml ps

# Ver logs em tempo real
docker compose -f /opt/chatwoot/docker-compose.yml logs -f rails

# Parar tudo
docker compose -f /opt/chatwoot/docker-compose.yml down

# Iniciar tudo
docker compose -f /opt/chatwoot/docker-compose.yml up -d

# Reiniciar
docker compose -f /opt/chatwoot/docker-compose.yml restart

# ═══════════════════════════════════════════════════════════════════════════
# 4. MONITORAMENTO
# ═══════════════════════════════════════════════════════════════════════════

# Health check completo
bash /opt/chatwoot/health_check.sh

# Ver espaço em disco
du -sh /opt/chatwoot/*

# Ver memória usada
docker stats

# ═══════════════════════════════════════════════════════════════════════════
# 5. BACKUP E RESTORE
# ═══════════════════════════════════════════════════════════════════════════

# Fazer backup manual
/usr/local/bin/backup-chatwoot.sh

# Listar backups
ls -lh /opt/chatwoot/backups/

# Restaurar de backup
# 1. Parar: docker compose -f /opt/chatwoot/docker-compose.yml down
# 2. Restaurar: tar -xzf /opt/chatwoot/backups/seu_backup.tar.gz -C /opt/chatwoot/
# 3. Iniciar: docker compose -f /opt/chatwoot/docker-compose.yml up -d

# ═══════════════════════════════════════════════════════════════════════════
# 6. CONFIGURAÇÕES
# ═══════════════════════════════════════════════════════════════════════════

# Editar variáveis de ambiente
nano /opt/chatwoot/.env

# Editar Nginx config
nano /etc/nginx/sites-available/chatwoot

# Depois reiniciar:
# docker compose -f /opt/chatwoot/docker-compose.yml restart rails
# nginx -t && systemctl reload nginx

# ═══════════════════════════════════════════════════════════════════════════
# 7. ATUALIZAR CHATWOOT
# ═══════════════════════════════════════════════════════════════════════════

# Atualização segura (com backup)
/usr/local/bin/update-chatwoot.sh

# ═══════════════════════════════════════════════════════════════════════════
# 8. TROUBLESHOOTING
# ═══════════════════════════════════════════════════════════════════════════

# Aplicação não responde?
cd /opt/chatwoot
docker compose logs rails | tail -100

# PostgreSQL com problema?
docker compose exec postgres pg_isready -U postgres

# Redis com problema?
docker compose exec redis redis-cli ping

# Espaço cheio?
docker system prune -a --volumes -f

# Reiniciar tudo do zero
docker compose down
docker compose pull
docker compose up -d

# ═══════════════════════════════════════════════════════════════════════════
# 9. CONFIGURAR APÓS INSTALAÇÃO
# ═══════════════════════════════════════════════════════════════════════════

# Adicionar SMTP (para envio de emails)
# Editar: /opt/chatwoot/.env
# SMTP_HOST=smtp.seu-email.com
# SMTP_PORT=587
# SMTP_USERNAME=seu-email@domain.com
# SMTP_PASSWORD=sua-senha
# docker compose restart rails sidekiq

# Adicionar S3 (para armazenamento)
# Editar: /opt/chatwoot/.env
# S3_BUCKET_NAME=seu-bucket
# AWS_ACCESS_KEY_ID=sua-chave
# AWS_SECRET_ACCESS_KEY=seu-secret
# docker compose restart rails

# ═══════════════════════════════════════════════════════════════════════════
# 10. CONSOLE RAILS (executar scripts)
# ═══════════════════════════════════════════════════════════════════════════

# Acessar console
docker compose -f /opt/chatwoot/docker-compose.yml exec rails bundle exec rails c

# Dentro do console:
# User.first                           # Ver primeiro usuário
# Account.first                        # Ver primeira conta
# User.where(email: 'test@test.com')   # Buscar usuário

# ═══════════════════════════════════════════════════════════════════════════
# 11. INFORMAÇÕES ÚTEIS
# ═══════════════════════════════════════════════════════════════════════════

# Diretório de instalação: /opt/chatwoot
# Arquivo config:          /opt/chatwoot/.env
# Backups:                 /opt/chatwoot/backups/
# Logs Nginx:              /var/log/nginx/chatwoot_*.log
# Renovação SSL:           certbot renew --dry-run

# ═══════════════════════════════════════════════════════════════════════════

# Para mais informações:
# 📖 Docs: /opt/chatwoot/SETUP_VPS.md
# 🔧 Avançado: /opt/chatwoot/ADVANCED_CONFIG.md
# 📚 Geral: /opt/chatwoot/VPS_DEPLOYMENT_README.md
