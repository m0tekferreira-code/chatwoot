# 🚀 Chatwoot VPS - Guia de Instalação Completo

> Um script All-in-One que instala Chatwoot completo em uma VPS com um único comando

## 📋 Pré-Requisitos

Antes de começar, certifique-se que tem:

- **VPS com Ubuntu** (20.04, 22.04 ou 24.04)
- **Mínimo 2GB RAM** (recomendado 4GB+)
- **10GB espaço livre** em disco
- **Domínio** apontando para o IP da VPS
- **Acesso root/sudo** ao servidor
- **Portas 80 e 443** abertas no firewall

## 🚀 Instalação Rápida (3 Passos)

### Passo 1: Preparar o Domínio ou Subdomínio

Você pode usar qualquer um destes:

- **Domínio principal**: `example.com` ou `chat.example.com`
- **Subdomínio simples**: `support.example.com`
- **Múltiplos subdomínios**: `chat.suporte.example.com`
- **Localhost** (apenas teste, sem SSL): `localhost`

Aponte seu domínio/subdomínio para o IP da VPS no seu registrador:

```
seu-dominio.com (ou subdominio.seu-dominio.com) → IP da VPS
```

Você pode testar com:
```bash
nslookup seu-dominio.com
```

Deve retornar o IP da sua VPS.

### Passo 2: Executar o Script (Escolha uma opção)

#### 🖥️ **Opção 1: Windows (PowerShell)**

1. Abra PowerShell e navegue até a pasta do Chatwoot
2. Execute:

```powershell
.\deploy.ps1
```

3. Será pedido:
   - Host/IP do servidor
   - Usuário SSH (padrão: root)
   - Porta SSH (padrão: 22)
   - Caminho da chave SSH (deixar em branco para senha)

#### 🍎/🐧 **Opção 2: Linux/macOS (Bash)**

1. Abra terminal
2. Navegue até a pasta do Chatwoot
3. Execute:

```bash
bash deploy.sh
```

4. Será pedido as mesmas informações

#### 🔗 **Opção 3: Direct SSH (Qualquer SO)**

Se você tem SSH instalado (qualquer SO):

```bash
ssh root@seu-servidor.com 'bash -s' < setup_vps.sh
```

Substitua `seu-servidor.com` pelo IP ou domínio da sua VPS.

### Passo 3: Responder as Perguntas do Instalador

Após executar o script, ele vai pedir:

| Pergunta | Exemplo | Notas |
|----------|---------|-------|
| **URL/Domínio** | chat.example.com, suporte.example.com, subdomain.domain.com | Pode ser domínio principal ou subdomínio(s). Deve estar apontando para a VPS |
| **Email SSL** | seu-email@example.com | Para renovação automática do certificado |
| **Email Admin** | admin@example.com | Email para fazer login no Chatwoot |
| **Nome Admin** | João Silva | Seu nome ou nome da empresa |
| **Senha Admin** | Segura123!@# | Digite com cuidado (mínimo 6 caracteres) |

> As senhas de PostgreSQL e Redis são geradas automaticamente com 32 caracteres.

## ⏱️ Tempo de Instalação

O script automatiza todos esses passos:

```
✓ Atualizar sistema        (~2 min)
✓ Instalar Docker          (~3 min)
✓ Instalar Nginx           (~1 min)
✓ Instalar Certbot (SSL)   (~1 min)
✓ Baixar imagens Docker    (~5-10 min)
✓ Iniciar containers       (~2 min)
✓ Inicializar banco dados  (~2 min)
✓ Configurar SSL           (~2 min)
───────────────────────────────────
  TOTAL: ~20 minutos
```

## ✅ Pronto! Agora Acesse

Após terminar, você verá um resumo com:

```
========================================
Chatwoot instalado com sucesso!
========================================

URL de Acesso:
  → https://chat.example.com

Credenciais:
  Email: seu-email@example.com
  Senha: (a senha que você definiu)

Comandos Úteis:
  Ver logs:           docker compose logs -f
  Parar serviços:     docker compose down
  Iniciar serviços:   docker compose up -d
```

1. **Abra no navegador**: `https://seu-dominio.com`
2. **Faça login** com o email e senha do admin
3. **Pronto!** Comece a usar o Chatwoot

## � Segurança - O Que o Script Garante

O script implementa automaticamente:

- 🔑 **Senhas seguras**: 32 caracteres aleatórios
- 🔒 **SSL/TLS**: Certificado Let's Encrypt automático
- 🔄 **Renovação SSL**: Automática via cron (nunca expira)
- 🛡️ **Headers de Segurança**: Proteção HTTP adicional
- 📝 **Debug Desabilitado**: Em produção
- 🔐 **Permissões Restritas**: Arquivo .env protegido
- 📦 **Limite de uploads**: 100MB máximo

## 🎯 Próximos Passos Após Instalação

### ✨ Exemplos de URLs Suportadas

O script suporta qualquer variação de domínio/subdomínio:

```
✓ example.com              (domínio simples)
✓ chat.example.com         (subdomínio simples)
✓ support.example.com      (outro subdomínio)
✓ api.chat.example.com     (subdomínio múltiplo)
✓ deep.support.sub.example.com (subdomínios aninhados)

✗ localhost (sem SSL, apenas para teste local)
✗ 192.168.1.1 (endereço IP sem domínio)
✗ exemplo.com.br (deve estar apontado no DNS)
```

### 1. Configure Canais de Comunicação

No painel do Chatwoot, vá para **Settings → Inboxes** e adicione:

- 💬 **Live Chat**: Para website
- 📧 **Email**: Receber e responder emails
- 📱 **WhatsApp**: WhatsApp Business API
- 👍 **Facebook**: Integração Facebook/Instagram
- 🐦 **Twitter**: Integração Twitter/X
- ✈️ **Telegram**: Bot do Telegram

### 2. Adicione Agentes

**Settings → Team** → Adicione seus agentes

### 3. Configure Email (SMTP)

Para enviar emails (confirmações, notificações):

1. Vá para **Settings**
2. Procure por **Mailer Configuration**
3. Preencha com seu provedor:

**Exemplo Gmail:**
```
SMTP Host: smtp.gmail.com
SMTP Port: 587
Username: seu-email@gmail.com
Password: seu-app-password (gerar em myaccount.google.com/apppasswords)
```

**Depois, no servidor:**

```bash
# Editar arquivo .env
nano /opt/chatwoot/.env

# Adicionar:
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=seu-email@gmail.com
SMTP_PASSWORD=seu-app-password

# Salvar (Ctrl+X, Y, Enter)

# Reiniciar serviços
cd /opt/chatwoot
docker compose restart rails sidekiq
```

### 4. Configure Armazenamento S3 (Opcional)

Para armazenar anexos em AWS S3:

```bash
nano /opt/chatwoot/.env

# Adicionar:
S3_BUCKET_NAME=seu-bucket-name
AWS_ACCESS_KEY_ID=sua-chave-aki
AWS_SECRET_ACCESS_KEY=seu-secret-key
AWS_REGION=us-east-1

# Reiniciar
cd /opt/chatwoot
docker compose restart rails
```

## 🛠️ Comandos Úteis Pós-Instalação

### Ver Status da Aplicação

```bash
# Ver todos os containers rodando
cd /opt/chatwoot
docker compose ps

# Ver logs em tempo real
docker compose logs -f rails

# Saída esperada:
# rails_1    | [2026-04-12 10:30:15] I, [#12345] INFO -- Rails: Started GET "/" for
```

### Parar e Iniciar Serviços

```bash
# Parar tudo
cd /opt/chatwoot
docker compose down

# Iniciar tudo
docker compose up -d

# Reiniciar um serviço específico
docker compose restart rails
docker compose restart sidekiq
```

### Fazer Backup Manual

```bash
# Executar backup
/usr/local/bin/backup-chatwoot.sh

# Ver backup criado
ls -lh /opt/chatwoot/backups/

# Saída:
# chatwoot_backup_20260412_103015.tar.gz (150M)
```

### Verificar Saúde do Sistema

```bash
# Script completo de verificação
bash /opt/chatwoot/health_check.sh

# Mostra:
# [✓] Docker está rodando
# [✓] Nginx está rodando
# [✓] PostgreSQL respondendo
# [✓] Redis respondendo
# [✓] Rails respondendo
# [!] Certificado expira em 88 dias
```

### Atualize o Chatwoot

```bash
# Atualizar para a última versão
/usr/local/bin/update-chatwoot.sh

# Faz automaticamente:
# 1. Backup
# 2. Download novas imagens
# 3. Executa migrations
# 4. Reinicia serviços
```

## 🐛 Troubleshooting

### Problema: "Não consigo acessar https://meu-dominio.com"

**Solução:**

1. Verifique se o domínio está apontado para a VPS:
```bash
nslookup seu-dominio.com
# Deve retornar o IP da sua VPS
```

2. Verifique se Nginx está rodando:
```bash
systemctl status nginx
# Active (running) = OK
```

3. Verifique se o certificado SSL foi criado:
```bash
ls /etc/letsencrypt/live/
# Deve encontrar seu-dominio.com
```

4. Se nenhuma funcionou, reinicie tudo:
```bash
cd /opt/chatwoot
docker compose restart
systemctl restart nginx
```

### Problema: "Rails está lento ou não responde"

**Solução:**

```bash
# Ver logs de erro
cd /opt/chatwoot
docker compose logs rails | tail -50

# Procurar por: ERROR, exception, FATAL

# Se precisar reiniciar:
docker compose restart rails

# Se o banco cresceu muito:
docker compose exec postgres psql -U postgres chatwoot -c "SELECT pg_size_pretty(pg_database_size('chatwoot'));"
```

### Problema: "Espaço em disco cheio"

**Solução:**

```bash
# Ver uso de disco
df -h /opt/chatwoot

# Limpar containers inutilizados
docker system prune -a --volumes

# Limpar backups antigos (> 30 dias)
find /opt/chatwoot/backups -mtime +30 -delete
```

### Problema: "Esqueci minha senha de admin"

**Solução:**

1. Acesse o servidor
2. Abra o console Rails:

```bash
cd /opt/chatwoot
docker compose exec rails bundle exec rails console

# No console, execute:
user = User.find_by(email: 'seu-email@domain.com')
user.update(password: 'nova-senha-aqui')
exit
```

### Problema: "Certificado SSL expirou"

Não deveria acontecer (renovação é automática), mas se acontecer:

```bash
# Renovar manualmente
certbot renew --force-renewal

# Reiniciar Nginx
systemctl reload nginx
```

## 📊 Monitoramento Contínuo

Para monitorar o Chatwoot de forma contínua:

### Opção 1: Verificações Manuais Semanais

```bash
# Toda segunda-feira, verificar:
bash /opt/chatwoot/health_check.sh
```

### Opção 2: Alertas Automáticos

Configure um serviço externo como:
- **Uptime Robot**: https://uptimerobot.com
- **StatusPage.io**: Faz monitoramento
- **Sentry**: Monitora erros

### Opção 3: Com Sentry (Recomendado)

```bash
# 1. Criar conta em https://sentry.io
# 2. Editar /opt/chatwoot/.env
# 3. Adicionar: SENTRY_DSN=sua-dsn-aqui
# 4. Reiniciar: cd /opt/chatwoot && docker compose restart
```

## 📚 Documentação Adicional

Para informações avançadas:

| Tópico | Arquivo |
|--------|---------|
| Instalação passo-a-passo | [SETUP_VPS.md](./SETUP_VPS.md) |
| **Configuração de Domínio/Subdomínio** | **[DOMAIN_SETUP.md](./DOMAIN_SETUP.md)** ⭐ |
| Configurações avançadas | [ADVANCED_CONFIG.md](./ADVANCED_CONFIG.md) |
| Referência rápida | [QUICK_START.sh](./QUICK_START.sh) |

## 🆘 Precisa de Ajuda?

- 🌐 **Documentação oficial**: https://www.chatwoot.com/help-center
- 💬 **Discord Community**: https://discord.gg/chatwoot
- 🐛 **GitHub Issues**: https://github.com/chatwoot/chatwoot/issues
- 📖 **Guias**: https://github.com/chatwoot/chatwoot/discussions
