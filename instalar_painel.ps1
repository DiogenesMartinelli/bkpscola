# Instalador do Painel de Backups:
#   1. baixa o rclone portatil (se ainda nao existir)
#   2. autoriza o acesso ao Google Drive (abre o navegador, uma unica vez)
#   3. cria a tarefa agendada que atualiza o painel a cada 30 minutos
#   4. gera o painel e abre no navegador
$ErrorActionPreference = 'Stop'
$raiz      = Split-Path -Parent $MyInvocation.MyCommand.Path
$rcloneDir = Join-Path $raiz 'rclone'
$rclone    = Join-Path $rcloneDir 'rclone.exe'
$conf      = Join-Path $rcloneDir 'rclone.conf'

if (-not (Test-Path $rclone)) {
    Write-Host 'Baixando rclone (portatil, ~20 MB)...'
    $ProgressPreference = 'SilentlyContinue'
    $zip = Join-Path $env:TEMP 'rclone_painel.zip'
    $ext = Join-Path $env:TEMP 'rclone_painel_ext'
    Invoke-WebRequest 'https://downloads.rclone.org/rclone-current-windows-amd64.zip' -OutFile $zip
    Expand-Archive $zip $ext -Force
    New-Item -ItemType Directory -Force -Path $rcloneDir | Out-Null
    $exe = Get-ChildItem $ext -Recurse -Filter rclone.exe | Select-Object -First 1
    Copy-Item $exe.FullName $rclone -Force
    Remove-Item $zip -Force
    Remove-Item $ext -Recurse -Force
    Write-Host 'rclone instalado.'
}

if (-not (Test-Path $conf)) {
    Write-Host ''
    Write-Host 'O navegador vai abrir - faca login na conta Google dos backups e clique em PERMITIR...'
    & $rclone config create gdrive drive scope=drive.file --config $conf
    if (-not (Test-Path $conf)) { throw 'Autorizacao do Google Drive nao concluida.' }
}

Write-Host 'Criando tarefa agendada (atualiza o painel a cada 30 min)...'
try {
    $acao     = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + (Join-Path $raiz 'painel_oculto.vbs') + '"')
    $gatilho  = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration (New-TimeSpan -Days 3650)
    $ajustes  = New-ScheduledTaskSettingsSet -Priority 4 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    Register-ScheduledTask -TaskName 'Painel Backup Scola' -Action $acao -Trigger $gatilho -Settings $ajustes -Force | Out-Null
    Write-Host 'Tarefa criada.'
} catch {
    Write-Host ('Aviso: nao consegui criar a tarefa agendada (' + $_.Exception.Message + '). O painel ainda funciona pelo painel.bat.')
}

Write-Host 'Gerando o painel...'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $raiz 'gerar_painel.ps1')
Start-Process (Join-Path $raiz 'painel.html')
Write-Host ''
Write-Host 'Instalacao concluida! O painel abriu no navegador.'
