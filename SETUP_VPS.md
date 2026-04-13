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
- **Domínio** apontando para o IP da VPS
- **Porta 80 e 443** abertas no firewall
- **Mínimo 2GB RAM** (recomendado 4GB+)
- **10GB espaço livre em disco** (recomendado 20GB+)

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

Durante a execução, você será solicitado a informar:

1. **Domínio**: `chat.example.com` (seu domínio já deve apontar para a VPS)
2. **Email**: Email para certificado Let's Encrypt
3. **Email Admin**: Email do administrador do Chatwoot
4. **Nome Admin**: Nome do administrador
5. **Senha Admin**: Senha para login no Chatwoot

> As senhas de banco de dados e Redis são geradas automaticamente de forma segura.

## ⏱️ Tempo de Instalação

- Atualização do sistema: ~2-5 minutos
- Download de imagens Docker: ~5-10 minutos
- Inicialização dos serviços: ~2-3 minutos
- **Total**: ~15-20 minutos

## ✅ Validação Pós-Instalação

Após a conclusão, você verá um resumo com:

- ✓ URL de acesso: `https://seu-dominio.com`
- ✓ Credenciais de login
- ✓ Diretório de instalação: `/opt/chatwoot`
- ✓ Comandos úteis

## 📝 Variáveis de Ambiente (.env)

O script gera automaticamente um arquivo `.env` em `/opt/chatwoot/.env` com:

- Configurações de banco de dados PostgreSQL
- Configurações de Redis
- Chave secreta Rails
- URL da aplicação
- Email do administrador
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
