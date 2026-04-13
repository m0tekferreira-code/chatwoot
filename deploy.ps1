# Chatwoot VPS Setup Helper - Windows PowerShell
# 
# Facilita o upload e execução do script setup_vps.sh em uma VPS remota
#
# Uso: .\deploy.ps1

# Cores
function Write-Success { Write-Host "[✓] $args" -ForegroundColor Green }
function Write-Error-Custom { Write-Host "[✗] $args" -ForegroundColor Red }
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Warning-Custom { Write-Host "[!] $args" -ForegroundColor Yellow }

Clear-Host

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║  Chatwoot VPS Deploy Helper            ║" -ForegroundColor Blue
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Verificar se o script existe
if (-not (Test-Path "./setup_vps.sh")) {
    Write-Error-Custom "setup_vps.sh não encontrado no diretório atual"
    exit 1
}

# Perguntar dados do servidor
Write-Warning-Custom "Digite os dados da sua VPS:"
$ServerHost = Read-Host "Host/IP do servidor"
$ServerUser = Read-Host "Usuário SSH (padrão: root)"
if ([string]::IsNullOrEmpty($ServerUser)) { $ServerUser = "root" }

$ServerPort = Read-Host "Porta SSH (padrão: 22)"
if ([string]::IsNullOrEmpty($ServerPort)) { $ServerPort = 22 }

# Verificar se possui chave SSH
$SshKey = Read-Host "Caminho para chave SSH (deixar em branco para senha): "

# Construir parametros de conexão
$SshParams = @("-p", $ServerPort, "$($ServerUser)@$($ServerHost)")
if (-not [string]::IsNullOrEmpty($SshKey)) {
    $SshParams += @("-i", $SshKey)
}

Write-Host ""
Write-Info "Testando conexão SSH..."

try {
    if ($SshKey) {
        # Com chave SSH
        $output = (ssh @SshParams "echo 'OK'" 2>&1)
    } else {
        # Com senha será pedido interativamente
        $output = (ssh @SshParams "echo 'OK'" 2>&1)
    }
    
    if ($output -like "*OK*" -or $LASTEXITCODE -eq 0) {
        Write-Success "Conexão SSH estabelecida"
    } else {
        Write-Error-Custom "Não foi possível conectar ao servidor"
        exit 1
    }
} catch {
    Write-Error-Custom "Erro ao conectar: $_"
    exit 1
}

Write-Host ""
Write-Info "Enviando script para o servidor..."

try {
    if ($SshKey) {
        scp -P $ServerPort -i $SshKey ./setup_vps.sh "$($ServerUser)@$($ServerHost):/tmp/setup_vps.sh"
    } else {
        scp -P $ServerPort ./setup_vps.sh "$($ServerUser)@$($ServerHost):/tmp/setup_vps.sh"
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Script enviado com sucesso"
    } else {
        Write-Error-Custom "Erro ao enviar script"
        exit 1
    }
} catch {
    Write-Error-Custom "Erro ao enviar: $_"
    exit 1
}

Write-Host ""
$RunNow = Read-Host "Deseja executar o script agora? (s/n)"

if ($RunNow -eq "s" -or $RunNow -eq "S") {
    Write-Host ""
    Write-Info "Conectando ao servidor para executar o script..."
    Write-Host ""
    
    if ($SshKey) {
        ssh @SshParams "bash /tmp/setup_vps.sh"
    } else {
        ssh @SshParams "bash /tmp/setup_vps.sh"
    }
    
    Write-Host ""
    Write-Success "Instalação concluída!"
} else {
    Write-Host ""
    Write-Warning-Custom "Para executar o script manualmente:"
    if ($SshKey) {
        Write-Host "  ssh -p $ServerPort -i $SshKey $ServerUser@$ServerHost 'bash /tmp/setup_vps.sh'"
    } else {
        Write-Host "  ssh -p $ServerPort $ServerUser@$ServerHost 'bash /tmp/setup_vps.sh'"
    }
}

Write-Host ""
