<#
.SYNOPSIS
  Empacota e assina módulos DayZ com o AddonBuilder (-packonly) para teste local.

.DESCRIPTION
  Para cada módulo (pasta com config.cpp) roda o AddonBuilder, grava o PBO assinado em
  <OutDir>\<OutModName>\addons e decide sucesso pelo TEXTO "Build Successful" do output, nunca pelo exit code
  (o AddonBuilder devolve 0 mesmo quando crasha). Copia a .bikey pública para <ServerDir>\keys.

  Por que -packonly: o build completo (binarização) falhou em todos os módulos neste setup, e o script é
  compilado pelo engine ao subir o servidor, não pelo AddonBuilder.
  Por que NÃO usar -exclude: crasha o AddonBuilder (FATAL ArgumentNullException) com exit code 0.

.PARAMETER Module
  Nomes de pastas dentro de ModsRoot (ou caminhos completos). Vazio com -All = todas as pastas com config.cpp.

.EXAMPLE
  .\build-addon.ps1 -Module MeuModulo
  .\build-addon.ps1 -All
#>
param(
    [string[]]$Module,
    [switch]$All
)

$ErrorActionPreference = 'Continue'
$cfgFile = Join-Path $PSScriptRoot 'config.local.ps1'
if (-not (Test-Path $cfgFile)) { Write-Error "Falta config.local.ps1 (copie de config.example.ps1)."; exit 2 }
. $cfgFile

foreach ($p in 'AddonBuilder', 'SignKey', 'PublicKey', 'ModsRoot') {
    if (-not (Test-Path $Cfg[$p])) { Write-Error "Caminho inexistente em config ($p): $($Cfg[$p])"; exit 2 }
}

# Cuidado: servidor ou client abertos travam o .pbo de destino.
$busy = Get-Process -Name 'DayZServer_x64', 'DayZ_x64' -ErrorAction SilentlyContinue
if ($busy) {
    Write-Warning ("Processo aberto: " + (($busy | ForEach-Object { $_.ProcessName }) -join ', ') +
        ". Feche antes de recompilar, ou o PBO ficará travado (Build failed em 'Copying PBO').")
}

$addonsOut = Join-Path (Join-Path $Cfg.OutDir $Cfg.OutModName) 'addons'
$keysOut   = Join-Path (Join-Path $Cfg.OutDir $Cfg.OutModName) 'keys'
New-Item -ItemType Directory -Force -Path $addonsOut, $keysOut | Out-Null

if ($All) {
    $dirs = Get-ChildItem -Path $Cfg.ModsRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'config.cpp') }
} else {
    if (-not $Module) { Write-Error "Informe -Module <nome> ou -All."; exit 2 }
    $dirs = foreach ($m in $Module) {
        $path = if (Test-Path $m) { $m } else { Join-Path $Cfg.ModsRoot $m }
        if (-not (Test-Path (Join-Path $path 'config.cpp'))) {
            Write-Warning "Sem config.cpp em $path (o módulo empacota, mas nada compila). Ignorado."
            continue
        }
        Get-Item $path
    }
}

$ok = @(); $fail = @()
foreach ($d in $dirs) {
    # Staging incremental: arquivo movido/renomeado/apagado ressuscita no PBO. Se você mudou arquivos de lugar,
    # apague a pasta %TEMP%\<modulo em minúsculas> antes de rodar.
    Write-Host "Empacotando $($d.Name) ..."
    $abArgs = @($d.FullName, $addonsOut, '-packonly', "-sign=$($Cfg.SignKey)", "-project=$($Cfg.ProjectRoot)")
    # Falha em "Packing" com exit 1 e sem detalhe: o -prefix automático quebra com espaço/pasta aninhada.
    # Se acontecer, adicione "-prefix=<NomeDoAddon>" a esta lista (ou remova o -project=).
    $out = & $Cfg.AddonBuilder @abArgs 2>&1 | Out-String
    if ($out -match 'Build Successful') { $ok += $d.Name; Write-Host "  [OK]   $($d.Name)" }
    else { $fail += $d.Name; Write-Host "  [FAIL] $($d.Name)"; Write-Host $out }
}

Copy-Item -Force $Cfg.PublicKey $keysOut
$serverKeys = Join-Path $Cfg.ServerDir 'keys'
if (Test-Path $serverKeys) { Copy-Item -Force $Cfg.PublicKey $serverKeys }  # verifySignatures = 2 exige a .bikey

Write-Host ""
Write-Host ("Resultado: {0} OK, {1} com falha." -f $ok.Count, $fail.Count)
if ($fail.Count) { Write-Host ("Falhas: " + ($fail -join ', ')) }
Write-Host "PBOs em: $addonsOut"
Write-Host "Lembrete: build bom não prova que o script compila; suba o servidor (start-server.ps1) para validar."
if ($fail.Count) { exit 1 } else { exit 0 }
