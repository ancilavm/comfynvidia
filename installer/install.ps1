# installer/install.ps1
$ErrorActionPreference = "Stop"

$root = Join-Path $PSScriptRoot ".."
$logDir = Join-Path $root "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir "install.log"

Start-Transcript -Path $logFile -Append

Write-Host "=== ComfyUI One-Click Installer (v2) ==="

function Ensure-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "Git found."
        return
    }
    throw "Git is not installed or not in PATH."
}

function Ensure-Python {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        $v = & python --version
        Write-Host "Python found: $v"
        return
    }
    throw "Python not found in PATH. (Next: we will auto-install Python.)"
}

Ensure-Git
Ensure-Python

$comfyDir = Join-Path $root "ComfyUI"

if (!(Test-Path $comfyDir)) {
    Write-Host "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git $comfyDir
} else {
    Write-Host "ComfyUI already exists, pulling updates..."
    Push-Location $comfyDir
    git pull
    Pop-Location
}

# Create venv
$venvDir = Join-Path $comfyDir "venv"
if (!(Test-Path $venvDir)) {
    Write-Host "Creating venv..."
    Push-Location $comfyDir
    python -m venv venv
    Pop-Location
} else {
    Write-Host "venv already exists."
}

$pip = Join-Path $venvDir "Scripts\pip.exe"
$py  = Join-Path $venvDir "Scripts\python.exe"

Write-Host "Upgrading pip..."
& $py -m pip install --upgrade pip

Write-Host "Installing requirements..."
Push-Location $comfyDir
& $pip install -r requirements.txt
Pop-Location

# Install custom nodes
$nodesFile = Join-Path $root "installer\nodes.list"
$customNodesDir = Join-Path $comfyDir "custom_nodes"
New-Item -ItemType Directory -Force -Path $customNodesDir | Out-Null

if (Test-Path $nodesFile) {
    Write-Host "Installing custom nodes..."
    $nodes = Get-Content $nodesFile | Where-Object { $_ -and (-not $_.StartsWith("#")) }

    foreach ($url in $nodes) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($url.TrimEnd("/"))
        $dest = Join-Path $customNodesDir $name

        if (Test-Path $dest) {
            Write-Host "Node exists: $name (pulling updates)"
            Push-Location $dest
            git pull
            Pop-Location
        } else {
            Write-Host "Cloning node: $name"
            git clone $url $dest
        }
    }
} else {
    Write-Host "No nodes.list found, skipping custom nodes."
}

Write-Host "DONE."
Stop-Transcript
