# Troubleshooting - Setup VPS Idempotente

## 🔍 Diagnóstico de Problemas

### Problema: Script falha na primeira execução

**Sintomas:**
```
[✗] Docker não consegue baixar imagens
[✗] Nginx não inicia
[✗] Certificado SSL falha
```

**Solução:**
```bash
# 1. Verifique conectividade
ping 8.8.8.8

# 2. Verifique espaço em disco
df -h /opt

# 3. Verifique portas livres
netstat -tuln | grep -E ':80|:443'

# 4. Se houver problema, execute novamente:
sudo bash setup_vps.sh
# Escolha: 2) REPAIR
```

---

### Problema: Cron jobs duplicados

**Sintomas:**
```bash
crontab -l
# Mostra múltiplas linhas iguais:
0 2 * * * /usr/local/bin/backup-chatwoot.sh
0 2 * * * /usr/local/bin/backup-chatwoot.sh
0 2 * * * /usr/local/bin/backup-chatwoot.sh
```

**Solução Manual:**
```bash
# Ver crontab atual
crontab -l

# Editar crontab
crontab -e

# Remover duplicatas manualmente (KL: :q! para sair)
# Manter apenas uma de cada

# Ou limpar tudo e rerun o script:
(crontab -l 2>/dev/null | grep -v "chatwoot" | crontab -)
sudo bash setup_vps.sh
# Escolha: 1) ATUALIZAR
```

---

### Problema: Nginx config corrompida

**Sintomas:**
```
[✗] Nginx não inicia
[✗] 502 Bad Gateway
[✗] Conexão recusada
```

**Diagnóstico:**
```bash
# Testar config Nginx
sudo nginx -t

# Ver erros específicos
sudo systemctl status nginx

# Ver logs
sudo tail -f /var/log/nginx/chatwoot_error.log
```

**Solução:**
```bash
# 1. Backup da config atual
sudo cp /etc/nginx/sites-available/chatwoot /etc/nginx/sites-available/chatwoot.broken

# 2. Remover config quebrada
sudo rm -f /etc/nginx/sites-available/chatwoot
sudo rm -f /etc/nginx/sites-enabled/chatwoot

# 3. Rodar setup novamente
sudo bash setup_vps.sh
# Escolha: 2) REPAIR
```

---

### Problema: Certificado SSL não renovado

**Sintomas:**
```
[!] SSL Certificate will expire in 15 days
[!] https://domain mostra aviso de certificado
```

**Checar status:**
```bash
# Ver certificados
sudo certbot certificates

# Testar renovação manual
sudo certbot renew --dry-run

# Ver logs de renovação
sudo tail -f /var/log/chatwoot_renewal.log

# Verificar cron job
crontab -l | grep renewal

# Ver erro específico
sudo certbot renew --verbose
```

**Solução:**
```bash
# 1. Renovar manualmente
sudo certbot renew --force-renewal

# 2. Se erro persistir, reconfigurar:
sudo rm -f /etc/nginx/sites-enabled/chatwoot
sudo bash setup_vps.sh
# Escolha: 1) ATUALIZAR
```

---

### Problema: Docker containers não iniciam

**Sintomas:**
```
[✗] Containers saem logo após iniciar
[!] Port 3000 não está respondendo
```

**Diagnóstico:**
```bash
# Ver status dos containers
cd /opt/chatwoot
docker compose ps

# Ver logs dos containers
docker compose logs rails

# Ver logs específico de erro
docker compose logs postgres

# Checar se porta 3000 está aberta
netstat -tuln | grep 3000
```

**Solução:**
```bash
# 1. Parar tudo
cd /opt/chatwoot
docker compose down

# 2. Remover volumes órfãos
docker compose down --remove-orphans

# 3. Limpar imagens não usadas
docker image prune -f

# 4. Tentar novamente
docker compose up -d

# 5. Aguardar alguns segundos
sleep 10

# 6. Ver se subiu
docker compose ps

# 7. Se persistir, usar setup:
sudo bash setup_vps.sh
# Escolha: 1) ATUALIZAR
```

---

### Problema: Senha banco de dados incorreta

**Sintomas:**
```
[✗] FATAL: password authentication failed
[!] SCRAM authentication rejected
```

**Solução:**
```bash
# 1. Ver senhas atuais em .env
cat /opt/chatwoot/.env | grep POSTGRES_PASSWORD

# 2. Resetar banco de dados
cd /opt/chatwoot
docker compose down
docker volume rm chatwoot_postgres_data
docker compose up -d postgres

# 3. Aguardar postgres iniciar
sleep 10

# 4. Recriar banco
docker compose exec postgres createdb -U postgres chatwoot

# 5. Subir tudo de novo
docker compose up -d

# 6. Ou usar setup cleanly:
sudo bash setup_vps.sh
# Escolha: 1) ATUALIZAR
```

---

### Problema: Espaço em disco cheio

**Sintomas:**
```
[!] Docker não consegue criar volumes
[✗] Aplicação falha aleatoriamente
```

**Solução:**
```bash
# 1. Checar espaço
df -h

# 2. Limpar Docker
docker system prune -a
docker volume prune

# 3. Limpar logs antigos
sudo find /var/log -name "*.log" -mtime +30 -delete

# 4. Limpar backups antigos (se não forem do último mês)
cd /opt/chatwoot/backups
ls -lth  # Ver backups por data
rm chatwoot_backup_*.tar.gz  # Remover antigos manualmente

# 5. Verificar novamente
df -h
```

---

### Problema: Restaurar de Backup

**Se tudo deu errado, restaurar:**

```bash
# 1. Ver backups disponíveis
ls -la /opt/chatwoot/backups/

# 2. Restaurar .env e config Nginx
cd /opt/chatwoot/backups/pre_change_20240115_143022

# Copiar .env
cp .env /opt/chatwoot/.env

# Copiar config Nginx
sudo cp nginx_config /etc/nginx/sites-available/chatwoot

# 3. Recarregar Nginx
sudo systemctl reload nginx

# 4. Verificar status
docker compose ps
curl http://127.0.0.1:3000/health_check
```

---

### Problema: Ciclo infinito de instalação

**Sintomas:**
```
Script não termina ou pede input continuamente
```

**Solução:**
```bash
# 1. Parar o script
Ctrl+C

# 2. Remover arquivo de lock (se existir)
sudo rm -f /opt/chatwoot/.setup.lock

# 3. Ver onde parou
tail -100 /opt/chatwoot/installation_state.log

# 4. Investigar o último erro
cd /opt/chatwoot
docker compose logs -f

# 5. Tentar rodar novamente
sudo bash setup_vps.sh
```

---

## 🛠️ Limpeza Manual Completa

Se quiser limpar TUDO e começar do zero:

```bash
# ⚠️ AVISO: Isto apagará TUDO incluso dados!

# 1. Parar containers
cd /opt/chatwoot
docker compose down
docker volume rm chatwoot_postgres_data chatwoot_redis_data

# 2. Remover aplicação
sudo rm -rf /opt/chatwoot

# 3. Remover config Nginx
sudo rm -f /etc/nginx/sites-available/chatwoot
sudo rm -f /etc/nginx/sites-enabled/chatwoot

# 4. Limpar cron jobs
(crontab -l 2>/dev/null | grep -v chatwoot | crontab -)

# 5. Remover certificates (se quiser certificado novo)
sudo rm -rf /etc/letsencrypt/live/chat.praxisis.com.br

# 6. Agora rodar setup novo
sudo bash setup_vps.sh
# Escolha: 1) ATUALIZAR
```

---

## 🔍 Comandos Úteis de Diagnóstico

```bash
# Status geral
docker compose -f /opt/chatwoot/docker-compose.yml ps

# Logs em tempo real
docker compose -f /opt/chatwoot/docker-compose.yml logs -f rails

# Verificar saúde da aplicação
curl -v http://127.0.0.1:3000/health_check

# Verificar SSL
curl -I https://chat.praxisis.com.br

# Verificar certificado
sudo certbot certificates

# Verificar Nginx
sudo nginx -t
sudo systemctl status nginx

# Ver cron jobs
crontab -l

# Espaço em disco
df -h /opt

# Memória/CPU
docker stats

# Arquivos por tamanho
du -sh /opt/chatwoot/*

# Ports em uso
netstat -tuln | grep LISTEN
```

---

## 📞 Emergency Contact

Se nada funcionar:

1. **Coleta de informações:**
   ```bash
   docker compose logs > /tmp/docker-logs.txt
   sudo tail -100 /var/log/nginx/chatwoot_error.log > /tmp/nginx-logs.txt
   cat /opt/chatwoot/installation_state.log > /tmp/setup-state.txt
   ```

2. **Compartilhe:**
   - `/tmp/docker-logs.txt`
   - `/tmp/nginx-logs.txt`
   - `/tmp/setup-state.txt`
   - Output do: `df -h`
   - Output do: `docker ps -a`

3. **Descreva:**
   - Qual foi o erro exato?
   - Quantas vezes rodou o script?
   - Qual opção escolheu (1/2/3)?
   - Qual é o seu VPS (DigitalOcean/Contabo/etc)?
   - Qual versão do Ubuntu?

---

## ✅ Sistema Saudável

Um sistema saudável tem:

```bash
# ✓ Todos containers rodando
docker compose ps
# CONTAINER       STATUS               NAMES
# postgres        Up 5 minutes          postgres
# redis           Up 5 minutes          redis  
# rails           Up 5 minutes          rails
# nginx           Up 5 minutes (external) nginx
# sidekiq         Up 5 minutes          sidekiq
# webpack         Up 5 minutes          webpack

# ✓ DNS resolvendo
dig chat.praxisis.com.br
# Deve retornar IP da VPS

# ✓ Nginx respondendo
curl -I https://chat.praxisis.com.br
# HTTP/2 301 ou esperado

# ✓ Apply respondendo
curl http://127.0.0.1:3000/health_check
# {"success":true}

# ✓ Cron jobs configurados
crontab -l | grep chatwoot
# Deve mostrar 2 jobs (backup e renewal)

# ✓ Certificado válido
sudo certbot certificates | grep chat.praxisis.com.br
# Valid até: data no futuro

# ✓ Espaço em disco
df -h /opt
# Use% <= 80%
```
