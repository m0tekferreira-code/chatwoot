# 🚀 Chatwoot VPS Setup - Guia de Instalação

Script automático para instalar e configurar o Chatwoot completo em uma VPS.

## ✨ O que o script faz

- ✅ Instala Docker e Docker Compose
- ✅ Instala e configura Nginx como reverse proxy
- ✅ Configura certificado SSL com Let's Encrypt
- ✅ Cria arquivo `.env` com variáveis seguras
- ✅ Inicia todos os serviços (Rails, Sidekiq, PostgreSQL, Redis)
- ✅ Inicializa o banco de dados
- ✅ Configura renovação automática de SSL
- ✅ Cria scripts de backup e atualização

## 📋 Pré-requisitos

- **VPS com Ubuntu** 20.04, 22.04 ou 24.04
- **Acesso root** ou usuário com permissão sudo
- **Domínio ou Subdomínio** apontando para o IP da VPS (veja abaixo)
- **Porta 80 e 443** abertas no firewall
- **Mínimo 2GB RAM** (recomendado 4GB+)
- **10GB espaço livre em disco** (recomendado 20GB+)

## 🌐 Configuração de Domínio/Subdomínio

### O que o script aceita?

O script foi construído para aceitar **qualquer tipo de domínio ou subdomínio**:

| Tipo | Exemplo | Funciona? |
|------|---------|-----------|
| Domínio raiz | `example.com` | ✅ Sim |
| Subdomínio simples | `chat.example.com` | ✅ Sim |
| Outro subdomínio | `support.example.com` | ✅ Sim |
| Subdomínios aninhados | `api.chat.example.com` | ✅ Sim |
| Múltiplos subdomínios | `chat.api.suporte.example.com` | ✅ Sim |
| Localhost | `localhost` | ⚠️ Sem SSL (teste local) |
| Endereço IP | `192.168.1.1` | ❌ Não (sem domínio) |

### Como configurar no seu registrador?

1. Acesse o painel de controle do seu registrador (GoDaddy, Namecheap, etc)
2. Procure por **DNS** ou **Registros DNS**
3. Adicione um registro **A** apontando para o IP da sua VPS:

```
Nome:     chat.example.com    (ou seu-subdominio.seu-dominio.com)
Tipo:     A (Address)
Valor:    123.45.67.89        (IP da sua VPS)
TTL:      3600                (padrão)
```

4. Aguarde a propagação (pode levar até 48 horas, mas geralmente é instantâneo)

5. Teste a configuração:

```bash
# No seu computador
nslookup chat.example.com

# Deve retornar algo como:
# Name:   chat.example.com
# Address: 123.45.67.89
```

### Dica: Usar um subdomínio é mais seguro! 🔒

Recomendações:

```
❌ Não use:  example.com (domínio raiz)
✅ Use:      chat.example.com (subdomínio específico)
```

**Por quê?** Usar subdomínios oferece:
- Isolamento melhor da infraestrutura do seu site principal
- Facilita migração/mudança de servidores
- Melhor controle de SSL
- Mais flexibilidade para múltiplas aplicações

> 📖 **Para configuração detalhada de domínios e subdomínios, veja:** [DOMAIN_SETUP.md](./DOMAIN_SETUP.md)

## 🔧 Como usar

### Opção 1: Download e Execução Local

1. **Copie o script para sua VPS:**

```bash
# Usando SCP (do seu computador)
scp setup_vps.sh root@seu-servidor.com:/root/

# Conecte ao servidor
ssh root@seu-servidor.com
```

2. **Execute o script:**

```bash
sudo bash setup_vps.sh
```

### Opção 2: Download e Execução Remota (One-liner)

```bash
ssh root@seu-servidor.com 'bash -s' < setup_vps.sh
```

### Opção 3: Download Direto da URL

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/seu-user/seu-fork/master/setup_vps.sh)"
```

## ❓ O que o script vai perguntar

Durante a execução, o script fará as seguintes perguntas de forma interativa:

### 1. **URL/Domínio** (Obrigatório)
```
Exemplos válidos:
  chat.example.com          ✅ Subdomínio simples
  support.example.com       ✅ Outro subdomínio
  api.chat.example.com      ✅ Subdomínios aninhados
  example.com               ✅ Domínio raiz (se preferir)
```
**Nota:** Deve estar apontado no DNS para o IP da sua VPS

### 2. **Email para Certificado SSL** (Obrigatório)
```
admin@example.com
```
Usar um email real para receber notificações sobre renovação do certificado

### 3. **Email do Administrador** (Obrigatório)
```
seu-email@example.com
```
Este é o email que você usará para fazer login no Chatwoot

### 4. **Nome do Administrador** (Obrigatório)
```
João Silva
```
Seu nome ou nome da sua empresa

### 5. **Senha do Administrador** (Obrigatório)
```
Mín. 6 caracteres, não será exibida enquanto digita
```

### Senhas Geradas Automaticamente
O script **gera automaticamente** senhas seguras para:
- PostgreSQL: 32 caracteres aleatórios
- Redis: 32 caracteres aleatórios
- Rails Secret: 32 caracteres aleatórios

Você **não precisa** defini-las, ficam salvas em `.env`

## ⏱️ Tempo de Instalação

- Atualização do sistema: ~2-5 minutos
- Download de imagens Docker: ~5-10 minutos
- Inicialização dos serviços: ~2-3 minutos
- **Total**: ~15-20 minutos

## ✅ Resumo Após Instalação Bem-Sucedida

O script exibirá um resumo como este:

```
═══════════════════════════════════════════════════
✓ Chatwoot instalado com sucesso!
═══════════════════════════════════════════════════

🌐 ACESSAR A APLICAÇÃO
───────────────────────────────────────────────────
  URL: https://chat.example.com

👤 CREDENCIAIS DE LOGIN
───────────────────────────────────────────────────
  Email: seu-email@example.com
  Nome:  João Silva
  Senha: (a que você definiu)

📁 LOCALIZAÇÃO DOS ARQUIVOS
───────────────────────────────────────────────────
  Aplicação:  /opt/chatwoot
  Config:     /opt/chatwoot/.env
  Nginx:      /etc/nginx/sites-available/chatwoot
  Backups:    /opt/chatwoot/backups/

⚙️  CERTIFICADO SSL
───────────────────────────────────────────────────
  Domínio:   chat.example.com
  Email:     admin@example.com
  Status:    ✓ Ativo (renovação automática)
```

## 📝 Arquivo `.env`

O script gera automaticamente um arquivo `.env` em `/opt/chatwoot/.env` com:

- ✅ Configurações de banco de dados PostgreSQL
- ✅ Configurações de Redis
- ✅ Chave secreta Rails
- ✅ URL da aplicação (seu domínio)
- ✅ Email do administrador
- **Opcional**: Configurações de SMTP, S3, Sentry, etc.

Para editar: `nano /opt/chatwoot/.env`

## 🛠️ Comandos Úteis Pós-Instalação

### Ver logs em tempo real
```bash
cd /opt/chatwoot
docker compose logs -f rails
```

### Parar/Iniciar serviços
```bash
cd /opt/chatwoot
docker compose down    # Parar
docker compose up -d   # Iniciar
```

### Fazer backup manual
```bash
/usr/local/bin/backup-chatwoot.sh
```

### Atualizar Chatwoot
```bash
/usr/local/bin/update-chatwoot.sh
```

### Acessar console Rails
```bash
cd /opt/chatwoot
docker compose exec rails bundle exec rails console
```

### Ver status dos containers
```bash
cd /opt/chatwoot
docker compose ps
```

## 🔐 Segurança

O script realiza:

- ✅ Geração de senhas seguras (32 caracteres)
- ✅ Certificado SSL com renovação automática
- ✅ Headers de segurança HTTP
- ✅ Arquivo `.env` com permissões restritas (600)
- ✅ Desabilitação de debug em produção
- ✅ Limite de tamanho de upload: 100MB

### ⚠️ Melhorias recomendadas após instalação:

1. **Firewall**: Abra apenas as portas necessárias (80, 443, SSH)
   ```bash
   ufw allow 22/tcp
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```

2. **Fail2Ban**: Proteja contra força bruta
   ```bash
   apt-get install fail2ban
   systemctl enable fail2ban
   ```

3. **Backup Externo**: Configure backup para solução externa (AWS S3, etc)

4. **Monitoramento**: Configure alertas e monitoramento

## 📦 Backups

O script já configura:

- ✅ Backup automático diário às 02:00
- ✅ Retenção de 7 dias de backups
- ✅ Localização: `/opt/chatwoot/backups/`

Para testar:
```bash
/usr/local/bin/backup-chatwoot.sh
ls -lah /opt/chatwoot/backups/
```

## 🔄 Atualizações

O script cria um script de atualização automática:

```bash
/usr/local/bin/update-chatwoot.sh
```

Este script:
1. Faz backup antes de atualizar
2. Baixa novas imagens Docker
3. Executa migrations
4. Reinicia os serviços

## 🐛 Troubleshooting

### Aplicação não responde

```bash
# Verificar logs
cd /opt/chatwoot
docker compose logs -f rails

# Reiniciar
docker compose restart
```

### Certificado SSL expirado (não deve acontecer)

```bash
certbot renew --force-renewal
```

### Erro de permissão ao executar

```bash
# Certifique-se de usar sudo
sudo bash setup_vps.sh
```

### Porta já em uso

```bash
# Verificar qual processo está usando
lsof -i :80
lsof -i :443
```

## 📧 Configuração de SMTP (Email)

Para que o Chatwoot envie emails:

1. Edite `/opt/chatwoot/.env`
2. Configure as variáveis SMTP:
   ```
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=seu-email@gmail.com
   SMTP_PASSWORD=sua-senha
   SMTP_AUTHENTICATION=login
   SMTP_ENABLE_STARTTLS_AUTO=true
   ```
3. Reinicie os serviços: `docker compose restart rails sidekiq`

## 🪣 Configuração de S3 (Armazenamento)

Para armazenar anexos no AWS S3:

1. Edite `/opt/chatwoot/.env`
2. Configure:
   ```
   S3_BUCKET_NAME=seu-bucket
   AWS_ACCESS_KEY_ID=sua-chave
   AWS_SECRET_ACCESS_KEY=seu-secret
   AWS_REGION=us-east-1
   ```
3. Reinicie: `docker compose restart rails`

## 📊 Monitoramento com Sentry

Para monitorar erros:

1. Crie conta em https://sentry.io
2. Edite `/opt/chatwoot/.env`
3. Configure: `SENTRY_DSN=sua-dsn`
4. Reinicie: `docker compose restart rails sidekiq`

## 🚀 Próximos Passos

1. **Acessar**: Abra https://seu-dominio.com
2. **Login**: Use email e senha do admin
3. **Configurar Canais**: Adicione Facebook, WhatsApp, Email, etc
4. **Adicionar Agentes**: Convide sua equipe
5. **Customizar**: Configure marca, emails, automações, etc

## ❓ Perguntas?

Para problemas:

- Documentação Chatwoot: https://www.chatwoot.com/help-center
- GitHub Issues: https://github.com/chatwoot/chatwoot/issues
- Discord Community: https://discord.gg/chatwoot

## 📄 Licença

Este script é fornecido como está. O Chatwoot é opensource bajo a licença MIT.

---

**Última atualização**: Abril 2026
