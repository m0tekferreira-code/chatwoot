# 🌐 Configuração de Domínio/Subdomínio para Chatwoot VPS

> Guia completo sobre como configurar domínios e subdomínios para funcionar com o Chatwoot

## 📋 Tipos Suportados

O setup_vps.sh suporta:

| Tipo | Exemplo | Recomendado? | Notas |
|------|---------|--------------|-------|
| **Domínio Raiz** | `example.com` | ⚠️ Possível | Usa domínio principal inteiro |
| **Subdomínio Simples** | `chat.example.com` | ✅ **SIM** | Mais seguro e flexível |
| **Subdomínio Simples 2** | `support.example.com` | ✅ **SIM** | Outro subdomínio diferente |
| **Múltiplos Subdomínios** | `api.chat.example.com` | ✅ Sim | Também funciona |
| **Aninhados Profundos** | `chat.api.suporte.example.com` | ✅ Sim | Mas mais complexo |
| **Localhost** | `localhost` | ❌ Não | Sem SSL, teste local |
| **IP Puro** | `192.168.1.1` | ❌ Não | Não funciona |

## ✅ O Que o Script Aceita na Pergunta de URL

Quando o script perguntar:

```
Digite a URL/domínio para acessar o Chatwoot:
```

Você pode digitar qualquer um destes (com DNS apontado):

```
✅ chat.example.com
✅ support.example.com
✅ api.suporte.example.com
✅ example.com
✅ meu-dominio.com.br
✅ www.example.com
✅ qualquer-coisa.seu-dominio.com
```

## 🎯 Recomendação: Use Subdomínio! 🔒

### Por Quê?

```
❌ DOMÍNIO RAIZ (example.com)
   - Menos flexível
   - Difícil mudar de servidor
   - Risco de quebrar site principal

✅ SUBDOMÍNIO (chat.example.com)
   - Muito mais flexível
   - Fácil de migrar
   - Isolado do site principal
   - Múltiplos Chatwoot possíveis
```

### Exemplo Prático

Se sua empresa é `example.com`:

```
❌ Não insira:    example.com
✅ Insira:        chat.example.com
                   (ou support, ou app, etc)
```

## 🔧 Como Configurar no Seu Registrador

### Passo 1: Escolha um Registrador

- GoDaddy
- Namecheap
- HostGator
- Locaweb
- RegistroBR
- Etc.

### Passo 2: Acesse o Painel DNS

1. Faça login no painel de controle
2. Procure por "DNS", "Registros DNS" ou "Gerenciar DNS"
3. Clique em "Adicionar Registro" ou "Add Record"

### Passo 3: Adicione um Registro A

```
Campo:      Valor:
────────────────────────────────────
Nome        chat.example.com     (seu domínio/subdomínio)
Tipo        A (Address)
Valor       123.45.67.89         (IP da sua VPS)
TTL         3600                 (padrão, em segundos)
```

> **Encontre seu IP da VPS:**
> - Digital Ocean: Dashboard → Droplet
> - AWS EC2: Elastic IPs
> - Linode: Instances
> - Qualquer VPS tem isso em um lugar fácil

### Passo 4: Aguarde Propagação

- **Geralmente**: 5-30 minutos
- **Máximo**: 48 horas
- **Status**: Você pode testar imediatamente, pode não funcionar ainda

### Passo 5: Teste a Configuração

#### No Windows (PowerShell):
```powershell
nslookup chat.example.com
```

#### No Linux/macOS:
```bash
nslookup chat.example.com
dig chat.example.com
host chat.example.com
ping chat.example.com
```

**Saída esperada:**
```
Name:   chat.example.com
Address: 123.45.67.89      ← Deve corresponder ao IP da sua VPS
```

## 🌍 Para Domínios .com.br (RegistroBR)

Se seu domínio foi registrado em RegistroBR (domínios .com.br):

1. Acesse: https://www.registro.br
2. Faça login com sua conta
3. Clique em "Meus Domínios"
4. Clique no domínio que quer configurar
5. Abra "Editar Nameserver" ou "Registros DNS"
6. Configure como descrito acima

> A propagação geralmente é instantânea para .com.br

## 🔀 Múltiplos Subdomínios (Múltiplos Chatwoot)

Se quiser instalar Chatwoot em múltiplos subdomínios:

```
chat.example.com     → Primeiro Chatwoot (porta 3000)
suporte.example.com  → Segundo Chatwoot (porta 3001)
api.example.com      → Terceiro Chatwoot (porta 3002)
```

Configure cada um separadamente:

```bash
# Servidor 1
./setup_vps.sh
# → digita: chat.example.com

# Servidor 2 (diferente VPS ou porta)
./setup_vps.sh
# → digita: suporte.example.com
```

## 🐛 Troubleshooting: Domínio Não Funciona

### 1. Verificar se DNS está apontado

```bash
nslookup seu-dominio.com
```

**Se retomar o IP:** DNS OK ✅
**Se não retornar o IP:** Espere mais um pouco (até 48h)

### 2. Verificar se servidor está respondendo

```bash
ping seu-dominio.com
```

Deve receber respostas do servidor

### 3. Verificar porta 80 (HTTP)

```bash
curl http://seu-dominio.com
```

Deve ver HTML (Nginx redirecionando)

### 4. Verificar certificado SSL

```bash
curl https://seu-dominio.com
```

Se funcionar: SSL OK ✅
Se der erro de certificado: Espere completar certbot

### 5. Ver logs do servidor

```bash
ssh root@seu-vps
cd /opt/chatwoot
docker compose logs nginx
docker compose logs rails
```

Procure por erros de DNS ou conexão

## ⚡ Alterar Domínio Após Instalação

Se já instalou mas quer mudar o domínio:

### 1. Adicione novo domínio no DNS

```
novo.example.com → 123.45.67.89
```

### 2. Edite o arquivo .env

```bash
ssh root@seu-vps
nano /opt/chatwoot/.env

# Procure por:
FRONTEND_URL=https://chat.example.com

# Mude para:
FRONTEND_URL=https://novo.example.com
```

### 3. Crie novo certificado SSL

```bash
certbot certonly -d novo.example.com
```

### 4. Atualize Nginx

```bash
nano /etc/nginx/sites-available/chatwoot

# Procure por:
server_name chat.example.com;

# Mude para:
server_name novo.example.com;
```

### 5. Reinicie serviços

```bash
cd /opt/chatwoot
docker compose restart rails
nginx -t
systemctl reload nginx
```

### 6. Teste

```bash
curl https://novo.example.com
```

## 📊 Verificar Domínios Cadastrados

### Ver qual domínio está configurado

```bash
ssh root@seu-vps

# Ver .env
grep FRONTEND_URL /opt/chatwoot/.env

# Ver Nginx
grep server_name /etc/nginx/sites-available/chatwoot

# Ver certificado SSL
ls /etc/letsencrypt/live/
```

## 💡 Dicas Avançadas

### 1. Usar CNAME em vez de A?

```
❌ chat.example.com   CNAME  vps.seuhost.com

✅ chat.example.com   A      123.45.67.89
```

Use **sempre A record diretamente** para Chatwoot

### 2. Usar www?

```
❌ www.example.com pode causar problemas
✅ example.com ou chat.example.com são melhores
```

Se usar www, configure assim:

```
www.example.com   A   123.45.67.89
example.com       A   123.45.67.89
```

### 3. Múltiplos domínios no mesmo Chatwoot?

Possível mas avançado (requer Nginx adicional).
Recomendado: teste uma vez antes.

---

## ❓ Precisa de Ajuda?

Se o domínio não funcionar:

1. Verifique DNS: `nslookup seu-dominio.com`
2. Verifique conectividade: `ping seu-dominio.com`
3. Verifique certificado: `curl https://seu-dominio.com`
4. Verifique logs: `docker compose logs`
5. Consulte: https://www.chatwoot.com/help-center

---

**Última atualização**: Abril 2026
**Compatível com**: setup_vps.sh v1.0+
