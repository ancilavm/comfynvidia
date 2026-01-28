# installer/install.ps1
# ComfyUI NVIDIA CUDA Installer (ComfyUI + Custom Nodes)
#
# Flow:
# 1) User manually installs Git and clones THIS repo
# 2) User runs this PowerShell script
# 3) Script installs Python (if missing) + ComfyUI + venv + CUDA Torch + nodes
# 4) Installs InsightFace (prebuilt wheel, no C++ build tools)
# 5) Optional: links external Models folder using extra_model_paths.yaml
# 6) Creates run/update BAT files

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "=== $msg ==="
}

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Fail($msg) {
    Write-Host ""
    Write-Host "ERROR: $msg" -ForegroundColor Red
    Write-Host ""
    exit 1
}

function Ensure-Git {
    if (!(Test-Command "git")) {
        Fail "Git not found. Please install Git first from https://git-scm.com/downloads and restart CMD/PowerShell."
    }
    git --version | Out-Host
}

function Ensure-WinGet {
    return (Test-Command "winget")
}

function Ensure-Python {
    if (Test-Command "python") {
        python --version | Out-Host
        return
    }

    Write-Step "Python not found - installing Python 3.11"

    if (!(Ensure-WinGet)) {
        Fail "winget not found. Install Python manually from https://www.python.org/downloads/windows/ (Python 3.11 recommended)."
    }

    # Install Python 3.11 (recommended)
    winget install -e --id Python.Python.3.11 --accept-package-agreements --accept-source-agreements
    Refresh-Path

    if (!(Test-Command "python")) {
        Fail "Python installation finished but python is still not available in PATH. Restart PC and run again."
    }

    python --version | Out-Host
}

function Ask-YesNo($prompt, $defaultYes=$true) {
    $suffix = $defaultYes ? "[Y/n]" : "[y/N]"
    $answer = Read-Host "$prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $defaultYes }
    $answer = $answer.Trim().ToLower()
    return ($answer -eq "y" -or $answer -eq "yes")
}

function Get-RepoNameFromUrl($url) {
    $u = $url.Trim()
    if ($u.EndsWith(".git")) { $u = $u.Substring(0, $u.Length - 4) }
    $parts = $u.Split("/")
    return $parts[$parts.Length - 1]
}

function Wait-ForUrl($url, $timeoutSeconds = 300) {
    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt $timeoutSeconds) {
        try {
            $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
            if ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500) {
                return $true
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

function Install-InsightFaceWheel {
    param(
        [string]$py,
        [string]$pip,
        [string]$rootDir
    )

    Write-Step "Installing InsightFace (prebuilt wheel - no C++ build tools)"

    $pyver = & $py -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
    $pyver = $pyver.Trim()
    Write-Host "Detected venv Python: $pyver"

    $wheelUrl = $null

    # Gourieff maintained wheels commonly used in ComfyUI ecosystem (ReActor/FaceID/etc.)
    if ($pyver -eq "3.10") {
        $wheelUrl = "https://github.com/Gourieff/Assets/raw/main/Insightface/insightface-0.7.3-cp310-cp310-win_amd64.whl"
    } elseif ($pyver -eq "3.11") {
        $wheelUrl = "https://github.com/Gourieff/Assets/raw/main/Insightface/insightface-0.7.3-cp311-cp311-win_amd64.whl"
    } elseif ($pyver -eq "3.12") {
        $wheelUrl = "https://github.com/Gourieff/Assets/raw/main/Insightface/insightface-0.7.3-cp312-cp312-win_amd64.whl"
    } else {
        throw "Unsupported Python version for InsightFace wheel: $pyver. Use Python 3.10/3.11/3.12."
    }

    $wheelDir = Join-Path $rootDir "installer\wheels"
    New-Item -ItemType Directory -Force -Path $wheelDir | Out-Null
    $wheelFile = Join-Path $wheelDir ([IO.Path]::GetFileName($wheelUrl))

    Write-Host "Downloading InsightFace wheel..."
    Invoke-WebRequest -Uri $wheelUrl -OutFile $wheelFile -UseBasicParsing

    Write-Host "Installing InsightFace wheel: $wheelFile"
    & $pip install --upgrade pip
    & $pip install $wheelFile

    # Common runtime deps
    & $pip install --upgrade onnxruntime opencv-python tqdm

    Write-Host "InsightFace installed."
}

function Write-ExtraModelPathsYaml {
    param(
        [string]$comfyDir,
        [string]$modelsPath
    )

    Write-Step "Generating extra_model_paths.yaml"

    $yamlPath = Join-Path $comfyDir "extra_model_paths.yaml"

    $sub = @{
        "checkpoints"    = (Join-Path $modelsPath "checkpoints")
        "loras"          = (Join-Path $modelsPath "loras")
        "vae"            = (Join-Path $modelsPath "vae")
        "controlnet"     = (Join-Path $modelsPath "controlnet")
        "clip"           = (Join-Path $modelsPath "clip")
        "clip_vision"    = (Join-Path $modelsPath "clip_vision")
        "upscale_models" = (Join-Path $modelsPath "upscale_models")
        "embeddings"     = (Join-Path $modelsPath "embeddings")
        "unet"           = (Join-Path $modelsPath "unet")
    }

    $lines = @()
    $lines += "# Auto-generated by comfyui-oneclick-installer"
    $lines += "# Base models folder: $modelsPath"
    $lines += "comfyui:"
    $lines += "  base_path: `"$modelsPath`""

    foreach ($k in $sub.Keys) {
        $lines += "  $k: `"$($sub[$k])`""
    }

    Set-Content -Path $yamlPath -Value $lines -Encoding UTF8
    Write-Host "Created: $yamlPath"
}

# -------------------------
# Paths + logging
# -------------------------
$root = Join-Path $PSScriptRoot ".."
$logDir = Join-Path $root "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$logFile = Join-Path $logDir "install.log"
Start-Transcript -Path $logFile -Append

Write-Step "ComfyUI Installer (NVIDIA CUDA)"

# -------------------------
# Prerequisites
# -------------------------
Write-Step "Checking prerequisites"
Ensure-Git
Ensure-Python

# -------------------------
# Setup directories
# -------------------------
$comfyDir = Join-Path $root "ComfyUI"
$venvDir  = Join-Path $comfyDir "venv"
$nodesDir = Join-Path $comfyDir "custom_nodes"
$nodesListPath = Join-Path $root "installer\nodes.list"

# -------------------------
# Install/update ComfyUI
# -------------------------
Write-Step "Installing/Updating ComfyUI"
if (!(Test-Path $comfyDir)) {
    Write-Host "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git $comfyDir
} else {
    Write-Host "ComfyUI exists, pulling updates..."
    Set-Location $comfyDir
    git pull
}

# -------------------------
# Create venv
# -------------------------
Write-Step "Creating virtual environment"
Set-Location $comfyDir

if (!(Test-Path $venvDir)) {
    python -m venv venv
    Write-Host "venv created."
} else {
    Write-Host "venv already exists."
}

$py  = Join-Path $venvDir "Scripts\python.exe"
$pip = Join-Path $venvDir "Scripts\pip.exe"

Write-Step "Upgrading pip"
& $py -m pip install --upgrade pip

# -------------------------
# Install PyTorch CUDA build
# -------------------------
Write-Step "Installing PyTorch (CUDA build cu121)"
& $pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# -------------------------
# Install ComfyUI requirements
# -------------------------
Write-Step "Installing ComfyUI requirements"
& $pip install -r (Join-Path $comfyDir "requirements.txt")

# -------------------------
# Install custom nodes
# -------------------------
Write-Step "Installing custom nodes"
New-Item -ItemType Directory -Force -Path $nodesDir | Out-Null

if (Test-Path $nodesListPath) {
    $nodeUrls = Get-Content $nodesListPath | Where-Object { $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#") }

    foreach ($url in $nodeUrls) {
        $name = Get-RepoNameFromUrl $url
        $target = Join-Path $nodesDir $name

        if (!(Test-Path $target)) {
            Write-Host "Cloning node: $name"
            git clone $url $target
        } else {
            Write-Host "Updating node: $name"
            Set-Location $target
            git pull
        }

        $req = Join-Path $target "requirements.txt"
        if (Test-Path $req) {
            Write-Host "Installing node requirements for $name"
            & $pip install -r $req
        }
    }
} else {
    Write-Host "No nodes.list found. Skipping custom nodes."
}

# -------------------------
# Install InsightFace (ONLY)
# -------------------------
Write-Step "InsightFace installation"
$installInsight = Ask-YesNo "Install InsightFace? (Recommended for FaceID nodes / IPAdapter FaceID)" $true
if ($installInsight) {
    Install-InsightFaceWheel -py $py -pip $pip -rootDir $root
} else {
    Write-Host "Skipping InsightFace."
}

# -------------------------
# External models folder
# -------------------------
Write-Step "Models folder setup"
$useExternalModels = Ask-YesNo "Do you want to link an existing Models folder from another drive?" $true
if ($useExternalModels) {
    $modelsPath = Read-Host "Enter full path to your existing Models folder (example: D:\AI\Models)"
    $modelsPath = $modelsPath.Trim('"')

    if (!(Test-Path $modelsPath)) {
        Write-Host "Folder not found: $modelsPath"
        Write-Host "Skipping models linking."
    } else {
        Write-ExtraModelPathsYaml -comfyDir $comfyDir -modelsPath $modelsPath
    }
} else {
    Write-Host "Skipping models linking."
}

# -------------------------
# Verification
# -------------------------
Write-Step "Verification (Torch + CUDA availability)"
& $py -c "import torch; print('torch version:', torch.__version__); print('cuda available:', torch.cuda.is_available()); print('cuda device count:', torch.cuda.device_count())"

# -------------------------
# Create helper BAT files
# -------------------------
Write-Step "Creating helper files (run/update)"

$runBat = Join-Path $root "run_comfyui.bat"
$updateBat = Join-Path $root "update_comfyui.bat"

$runContent = @"
@echo off
cd /d "%~dp0"
cd ComfyUI
venv\Scripts\python.exe main.py --listen 127.0.0.1 --port 8188
pause
"@

$updateContent = @"
@echo off
cd /d "%~dp0"

echo Updating ComfyUI...
cd ComfyUI
git pull

echo Updating custom nodes...
cd custom_nodes
for /d %%D in (*) do (
  echo Updating %%D ...
  cd %%D
  git pull
  cd ..
)

echo Done.
pause
"@

Set-Content -Path $runBat -Value $runContent -Encoding ASCII
Set-Content -Path $updateBat -Value $updateContent -Encoding ASCII

Write-Host "Created: run_comfyui.bat"
Write-Host "Created: update_comfyui.bat"

# -------------------------
# Health check
# -------------------------
Write-Step "Launching ComfyUI and running health check"

$serverUrl = "http://127.0.0.1:8188/"
$logServer = Join-Path $logDir "comfyui-server.log"

Write-Host "Starting ComfyUI..."
Write-Host "Logging output to: $logServer"

$comfyProcess = Start-Process `
    -FilePath $py `
    -ArgumentList "main.py --listen 127.0.0.1 --port 8188" `
    -WorkingDirectory $comfyDir `
    -RedirectStandardOutput $logServer `
    -RedirectStandardError $logServer `
    -PassThru `
    -WindowStyle Hidden

Write-Host "Waiting for ComfyUI at $serverUrl ..."
$ok = Wait-ForUrl $serverUrl 300

if (-not $ok) {
    Write-Host ""
    Write-Host "Health check FAILED. Last 80 lines of comfyui log:"
    Write-Host "--------------------------------------------------------"
    if (Test-Path $logServer) {
        Get-Content $logServer -Tail 80 | ForEach-Object { Write-Host $_ }
    }
    try { Stop-Process -Id $comfyProcess.Id -Force } catch {}
    throw "Health check FAILED: ComfyUI did not respond on port 8188."
}

Write-Host "Health check PASSED: ComfyUI responded."
Write-Host "Stopping ComfyUI..."
try { Stop-Process -Id $comfyProcess.Id -Force } catch {}

Write-Step "DONE"
Stop-Transcript
