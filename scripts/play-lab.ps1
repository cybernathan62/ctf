$ErrorActionPreference = "Stop"

$projectPath  = Split-Path -Parent $PSScriptRoot
$startScript  = Join-Path $PSScriptRoot "start-lab.ps1"
$logDir       = Join-Path $projectPath "logs"
$logFile      = Join-Path $logDir "player-start.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

Set-Location $projectPath

try {
    Write-Host ""
    Write-Host "[1/3] Initialisation de l'environnement..." -ForegroundColor Yellow

    $process = Start-Process `
        -FilePath "powershell" `
        -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-File", $startScript
        ) `
        -WorkingDirectory $projectPath `
        -RedirectStandardOutput $logFile `
        -RedirectStandardError $logFile `
        -WindowStyle Hidden `
        -PassThru

    while (-not $process.HasExited) {
        Start-Sleep -Seconds 2
    }

    if ($process.ExitCode -ne 0) {
        Write-Host ""
        Write-Host "Erreur pendant l'initialisation du lab." -ForegroundColor Red
        Write-Host "Voir le log admin : $logFile" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "[2/3] Configuration terminee..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1

    Write-Host "[3/3] Finalisation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1

    Write-Host ""
    Write-Host "Environnement pret." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}