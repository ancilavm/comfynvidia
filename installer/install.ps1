# installer/install.ps1
# Simple ComfyUI installer starter (will be improved)

$ErrorActionPreference = "Stop"

$root = Join-Path $PSScriptRoot ".."
$logDir = Join-Path $root "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$logFile = Join-Path $logDir "install.log"

Start-Transcript -Path $logFile -Append

Write-Host "=== ComfyUI One-Click Installer ==="

$comfyDir = Join-Path $root "ComfyUI"

if (!(Test-Path $comfyDir)) {
    Write-Host "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git $comfyDir
} else {
    Write-Host "ComfyUI already exists, pulling updates..."
    Set-Location $comfyDir
    git pull
}

Write-Host "DONE."
Stop-Transcript
