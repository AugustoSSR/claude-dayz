<#
.SYNOPSIS
  Sobe, confere e derruba o DayZServer LOCAL de teste (porta e profile isolados).

.DESCRIPTION
  -Start : sobe o servidor com o stack local + mods do Workshop e espera BootWaitSeconds.
  -Check : lê os logs mais novos do profile de teste e dá o veredito (erros de compile, crash, sinal de PASS).
  -Stop  : encerra SOMENTE o processo cujo profile é o de teste.

  Regras que este script aplica (cada uma custou um falso PASS ou um boot quebrado):
  * Start-Process com ARRAY de argumentos. Rodar em background pela ferramenta de shell ou como job mata o
    servidor quando a chamada termina. -ArgumentList como string com aspas embutidas corrompe a linha quando o
    exe tem espaço (os -mod= somem sem erro).
  * -mod= com vários caminhos separados por ';' só carrega o primeiro se algum tiver espaço: usa-se o caminho
    curto 8.3 e a lista sem aspas.
  * Profile isolado e porta própria: nunca o profile que guarda a configuração real dos mods.
  * Veredito só com log MAIS NOVO que o .pbo; crash_*.log novo é FAIL; processo vivo não é sucesso.
  * O servidor dedicado não compila UI: PASS aqui não vale para menu, layout ou HUD.

.EXAMPLE
  .\start-server.ps1 -Start -Check
  .\start-server.ps1 -Stop
#>
param(
    [switch]$Start,
    [switch]$Check,
    [switch]$Stop
)

$ErrorActionPreference = 'Continue'
$cfgFile = Join-Path $PSScriptRoot 'config.local.ps1'
if (-not (Test-Path $cfgFile)) { Write-Error "Falta config.local.ps1 (copie de config.example.ps1)."; exit 2 }
. $cfgFile

$exe     = Join-Path $Cfg.ServerDir 'DayZServer_x64.exe'
$profDir = Join-Path $Cfg.ServerDir $Cfg.ProfileName
$localMod = Join-Path $Cfg.OutDir $Cfg.OutModName

function Get-ShortPath([string]$p) {
    $fso = New-Object -ComObject Scripting.FileSystemObject
    if (Test-Path -PathType Container $p) { return $fso.GetFolder($p).ShortPath }
    return $fso.GetFile($p).ShortPath
}

function Get-TestProcess {
    Get-CimInstance Win32_Process -Filter "Name = 'DayZServer_x64.exe'" |
        Where-Object { $_.CommandLine -match ('-profiles=' + [regex]::Escape($Cfg.ProfileName) + '(\s|$)') }
}

if ($Stop) {
    $p = Get-TestProcess
    if ($p) { $p | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }; Write-Host "Servidor de teste encerrado." }
    else { Write-Host "Nenhum servidor de teste em execução (profile $($Cfg.ProfileName))." }
}

if ($Start) {
    if (-not (Test-Path $exe)) { Write-Error "DayZServer_x64.exe não encontrado em $($Cfg.ServerDir)"; exit 2 }
    if (-not (Test-Path (Join-Path $localMod 'addons'))) { Write-Error "Sem PBOs em $localMod. Rode build-addon.ps1."; exit 2 }
    if (Get-TestProcess) { Write-Error "Já existe um servidor de teste. Rode -Stop primeiro (uma instância por vez)."; exit 2 }

    $mods = @((Get-ShortPath $localMod))
    foreach ($id in $Cfg.WorkshopMods) {
        $m = Join-Path $Cfg.WorkshopDir $id
        if (-not (Test-Path $m)) { Write-Error "Mod do Workshop ausente: $m (bloqueador de ambiente)."; exit 2 }
        $mods += (Get-ShortPath $m)
    }
    $modArg = '-mod=' + ($mods -join ';')   # sem aspas, caminhos 8.3

    New-Item -ItemType Directory -Force -Path $profDir | Out-Null
    $argv = @(
        "-config=$($Cfg.ServerConfig)",
        "-port=$($Cfg.Port)",
        "-profiles=$($Cfg.ProfileName)",
        $modArg,
        '-dologs', '-adminlog', '-netlog', '-freezecheck'
    )
    $started = Get-Date
    Start-Process -FilePath $exe -ArgumentList $argv -WorkingDirectory $Cfg.ServerDir | Out-Null
    Write-Host "Servidor de teste iniciado às $started. Aguardando $($Cfg.BootWaitSeconds) s ..."
    Start-Sleep -Seconds $Cfg.BootWaitSeconds
}

if ($Check) {
    if (-not (Test-Path $profDir)) { Write-Error "Profile inexistente: $profDir"; exit 2 }
    $pbo = Get-ChildItem -Path (Join-Path $localMod 'addons') -Filter *.pbo -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $rpt = Get-ChildItem $profDir -Filter *.RPT -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $slog = Get-ChildItem $profDir -Filter 'script_*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $crash = Get-ChildItem $profDir -Filter 'crash_*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $rpt -and -not $slog) { Write-Host "BLOQUEIO DE AMBIENTE: nenhum log no profile de teste."; exit 3 }
    $logRef = if ($slog) { $slog } else { $rpt }
    if ($pbo -and $logRef.LastWriteTime -lt $pbo.LastWriteTime) {
        Write-Host "LOG VELHO: o log ($($logRef.LastWriteTime)) é anterior ao .pbo ($($pbo.LastWriteTime)). Relance e espere um log novo."
        exit 3
    }
    if ($crash -and $pbo -and $crash.LastWriteTime -gt $pbo.LastWriteTime) {
        Write-Host "FAIL: crash log novo: $($crash.FullName)"
        Get-Content $crash.FullName -TotalCount 25
        exit 1
    }
    $errs = @()
    foreach ($f in @($slog, $rpt)) {
        if ($f) { $errs += Select-String -Path $f.FullName -Pattern "SCRIPT\s*\(E\)", "Can't compile", "Multiple declaration", "Unknown type", "Can't find variable" }
    }
    if ($errs.Count -gt 0) {
        Write-Host "FAIL: o PRIMEIRO erro é a raiz; o resto costuma ser cascata."
        $errs | Select-Object -First 5 | ForEach-Object { Write-Host ("  " + $_.Path + ":" + $_.LineNumber + "  " + $_.Line.Trim()) }
        exit 1
    }
    $init = if ($rpt) { Select-String -Path $rpt.FullName -Pattern $Cfg.InitPattern | Select-Object -First 1 } else { $null }
    if ($init) { Write-Host "PASS: '$($Cfg.InitPattern)' no RPT atual ($($rpt.Name)). Lembrete: UI só se prova no client."; exit 0 }
    Write-Host "SEM CONCLUSÃO: sem erro e sem sinal de inicialização ainda. Confira se o processo consome CPU e olhe de novo (teto ~90 s)."
    exit 3
}
