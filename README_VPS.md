# Chatwoot - Instalação em VPS Linux

> Guia completo para instalar Chatwoot em uma VPS com um script automatizado

## 🚀 Quick Deploy em VPS Linux

Se quiser instalar o Chatwoot em uma VPS Linux com um **único comando**, temos um script automatizado para isso!

### ⚡ Instalação em 3 Passos (20 minutos)

#### 1️⃣ Preparar o Domínio

Aponte seu domínio/subdomínio para o IP da VPS:

```
chat.example.com → IP da sua VPS
```

**Aceita qualquer tipo:**
- `example.com` (domínio principal)
- `chat.example.com` (subdomínio)
- `support.example.com` (outro subdomínio)
- `api.chat.example.com` (aninhado)

#### 2️⃣ Executar o Script

**Linux/macOS:**
```bash
bash deploy.sh
```

**Windows (PowerShell):**
```powershell
.\deploy.ps1
```

**Qualquer SO (via SSH):**
```bash
ssh root@seu-servidor.com 'bash -s' < setup_vps.sh
```

#### 3️⃣ Responder as Perguntas

O script vai pedir:
- 🌐 **URL/Domínio** (ex: `chat.example.com`)
- 📧 **Email para certificado SSL** (ex: `admin@example.com`)
- 👤 **Email do administrador** (para login)
- 🔑 **Senha do administrador** (mínimo 6 caracteres)

**Tudo mais é automático!** ✅

### ✨ O Que o Script Faz Automaticamente

- ✅ Atualiza o sistema Ubuntu
- ✅ Instala Docker + Docker Compose
- ✅ Instala e configura Nginx como reverse proxy
- ✅ Gera certificado SSL com Let's Encrypt
- ✅ Configura renovação automática de SSL
- ✅ Inicia PostgreSQL, Redis, Rails e Sidekiq
- ✅ Inicializa o banco de dados
- ✅ Cria script de backup automático (diário)
- ✅ Cria script de atualização
- ✅ Valida se tudo está funcionando

**Tempo total: ~20 minutos**

### 📋 Pré-Requisitos

- **VPS com Ubuntu** 20.04, 22.04 ou 24.04
- **Domínio/Subdomínio** apontando para a VPS
- **Mínimo 2GB RAM** (recomendado 4GB+)
- **10GB espaço livre** em disco (recomendado 20GB+)
- **Acesso root ou sudo** ao servidor
- **Portas 80 e 443** abertas no firewall

### 🔧 Após a Instalação

**URL de Acesso:**
```
https://seu-dominio.com
```

**Credenciais:**
- Email: O que você definiu
- Senha: O que você definiu

**Próximas Ações:**
1. Fazer login
2. Adicionar canais (WhatsApp, Email, Facebook, etc)
3. Adicionar agentes
4. Configurar SMTP (para envio de emails)

---

## 📖 Documentação Detalhada

| Documento | Descrição |
|-----------|-----------|
| **[VPS_DEPLOYMENT_README.md](./VPS_DEPLOYMENT_README.md)** | Guia completo com todas as seções |
| **[SETUP_VPS.md](./SETUP_VPS.md)** | Passo-a-passo super detalhado |
| **[DOMAIN_SETUP.md](./DOMAIN_SETUP.md)** | Como configurar domínios e subdomínios ⭐ |
| **[ADVANCED_CONFIG.md](./ADVANCED_CONFIG.md)** | Integrações, SMTP, S3, Monitoramento |
| **[QUICK_START.sh](./QUICK_START.sh)** | Referência rápida de comandos úteis |

---

## 💡 Exemplos de Deploy

### Exemplo 1: Instalação Simples

```bash
# 1. Clone o repositório
git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot

# 2. Execute o script
bash deploy.sh

# 3. Siga os passos (vai pedir: URL, email, senha)
```

### Exemplo 2: VPS da DigitalOcean

```bash
# 1. Crie um droplet Ubuntu 22.04
# 2. Pegue o IP: ex 123.45.67.89
# 3. Aponte seu domínio para esse IP
# 4. Execute:
ssh root@123.45.67.89 'bash -s' < setup_vps.sh
```

### Exemplo 3: VPS AWS EC2

```bash
# 1. Conecte ao EC2
ssh -i sua-chave.pem ubuntu@seu-ec2-ip

# 2. Baixe o script
wget https://raw.githubusercontent.com/seu-fork/chatwoot/master/setup_vps.sh

# 3. Execute
sudo bash setup_vps.sh
```

### Exemplo 4: VPS Linode, Hetzner, etc

Sempre o mesmo processo:
1. Aponte o domínio para o IP da VPS
2. Execute: `ssh root@ip 'bash -s' < setup_vps.sh`
3. Responda as perguntas

---

## 🛠️ Comandos Úteis Pós-Instalação

### Ver Status da Aplicação
```bash
cd /opt/chatwoot
docker compose ps
```

### Ver Logs em Tempo Real
```bash
cd /opt/chatwoot
docker compose logs -f rails
```

### Fazer Backup Manual
```bash
/usr/local/bin/backup-chatwoot.sh
```

### Fazer Health Check
```bash
bash /opt/chatwoot/health_check.sh
```

### Atualizar Chatwoot
```bash
/usr/local/bin/update-chatwoot.sh
```

### Parar/Iniciar Serviços
```bash
cd /opt/chatwoot

# Parar tudo
docker compose down

# Iniciar tudo
docker compose up -d
```

---

## 🔐 Segurança

O script implementa automaticamente:

- 🔑 Senhas seguras (32 caracteres aleatórios)
- 🔒 Certificado SSL com Let's Encrypt
- 🔄 Renovação automática de SSL via cron
- 🛡️ Headers HTTP de segurança
- 📝 Debug desabilitado em produção
- 🔐 Permissões restritas nos arquivos

---

## 🆘 Troubleshooting

### Problema: Domínio não funciona

Verifique se o DNS está apontado:
```bash
nslookup seu-dominio.com
# Deve retornar o IP da sua VPS
```

### Problema: Rails não inicia

Ver logs para encontrar o erro:
```bash
cd /opt/chatwoot
docker compose logs rails | tail -50
```

### Problema: Certificado SSL expirado (não deve acontecer)

Renovar manualmente:
```bash
certbot renew --force-renewal
systemctl reload nginx
```

### Problema: Esqueceu a senha de admin

Redefinir pelo console Rails:
```bash
cd /opt/chatwoot
docker compose exec rails bundle exec rails console

# No console:
user = User.find_by(email: 'seu-email@domain.com')
user.update(password: 'nova-senha')
exit
```

Para mais troubleshooting, veja: [VPS_DEPLOYMENT_README.md](./VPS_DEPLOYMENT_README.md#-troubleshooting)

---

## 📊 Informações da Instalação

**Diretórios criados:**
```
/opt/chatwoot/              - Aplicação
/opt/chatwoot/.env          - Variáveis de ambiente
/opt/chatwoot/backups/      - Backups automáticos
/etc/nginx/sites-available/chatwoot - Config Nginx
/etc/letsencrypt/live/      - Certificados SSL
```

**Serviços rodando:**
- `rails` (Rails web server)
- `sidekiq` (Background jobs)
- `postgres` (Banco de dados)
- `redis` (Cache & sessions)
- `nginx` (Reverse proxy)

**Backups:**
- Automático: Diariamente às 02:00
- Retenção: 7 dias
- Local: `/opt/chatwoot/backups/`

**SSL:**
- Automático: Com Let's Encrypt
- Renovação: Automática via cron
- Email: Notificações de renovação

---

## 💬 Precisa de Ajuda?

- 🌐 [Documentação Oficial](https://www.chatwoot.com/help-center)
- 💻 [GitHub Issues](https://github.com/chatwoot/chatwoot/issues)
- 👥 [Discord Community](https://discord.gg/chatwoot)
- 📖 [Este README](./README_VPS.md)

---

## ✨ Próximas Ações Após Instalar

1. **Acessar**: `https://seu-dominio.com`
2. **Fazer Login** com as credenciais do admin
3. **Adicionar Canais**: WhatsApp, Email, Facebook, Telegram, etc
4. **Convidar Agentes**: Adicionar sua equipe
5. **Configurar SMTP**: Para envio de emails
6. **Personalizar**: Branding, automações, etc

---

**Versão**: 1.0  
**Última atualização**: Abril 2026  
**Compatível com**: Ubuntu 20.04, 22.04, 24.04  
**Mantido por**: Comunidade Chatwoot 🚀
