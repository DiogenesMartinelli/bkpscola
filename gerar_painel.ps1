# Gera o painel.html consultando os backups no Google Drive via rclone.
# Usado pelo painel.bat (abre no navegador) e pela tarefa agendada (oculto).
$ErrorActionPreference = 'Stop'

# ===== CONFIGURACAO =====
$pastaDrive = 'BackupSCOLA'   # pasta raiz dos backups no Google Drive

$raiz    = Split-Path -Parent $MyInvocation.MyCommand.Path
$rclone  = Join-Path $raiz 'rclone\rclone.exe'
$conf    = Join-Path $raiz 'rclone\rclone.conf'
$modelo  = Join-Path $raiz 'painel_template.html'
$saida   = Join-Path $raiz 'painel.html'
$logErro = Join-Path $raiz 'painel_erros.log'

$erro = $false
$arquivos = @()
$pastas = @()
try {
    # via cmd /c para o stderr do rclone (avisos) nao virar excecao no PS 5.1
    $json = cmd /c "`"$rclone`" lsjson `"gdrive:$pastaDrive`" -R --files-only --config `"$conf`" 2>nul"
    if ($LASTEXITCODE -ne 0) { throw "rclone retornou codigo $LASTEXITCODE" }
    $lista = ($json -join "`n") | ConvertFrom-Json
    foreach ($f in $lista) {
        $arquivos += @{ p = $f.Path; s = [long]$f.Size; m = $f.ModTime }
    }
    $jsonP = cmd /c "`"$rclone`" lsjson `"gdrive:$pastaDrive`" --dirs-only --config `"$conf`" 2>nul"
    if ($LASTEXITCODE -eq 0) {
        foreach ($p in (($jsonP -join "`n") | ConvertFrom-Json)) { $pastas += $p.Path }
    }
} catch {
    $erro = $true
    Add-Content $logErro ("{0} - falha ao consultar o Drive: {1}" -f (Get-Date -Format 'dd/MM/yyyy HH:mm:ss'), $_.Exception.Message)
}

$dados = @{
    geradoEm = (Get-Date -Format 'dd/MM/yyyy HH:mm')
    erro     = $erro
    pastas   = $pastas
    arquivos = $arquivos
}
$dadosJson = ConvertTo-Json $dados -Depth 5 -Compress

$template = Get-Content $modelo -Raw -Encoding UTF8
$html = $template.Replace('__DADOS__', $dadosJson)
Set-Content -Path $saida -Value $html -Encoding UTF8
