# installer/install.ps1
# ComfyUI One-Click Installer (CUDA/NVIDIA edition)
# Installs: ComfyUI + venv + requirements + PyTorch CUDA + custom nodes from nodes.list
# Then: Launch ComfyUI -> Wait for port 8188 -> Ping -> Shutdown

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "=== $msg ==="
}

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Get-RepoNameFromUrl($url) {
    $u = $url.Trim()
    if ($u.EndsWith(".git")) { $u = $u.Substring(0, $u.Length - 4) }
    $parts = $u.Split("/")
    return $parts[$parts.Length - 1]
}

function Wait-ForUrl($url, $timeoutSeconds = 90) {
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

$root = Join-Path $PSScriptRoot ".."
$logDir = Join-Path $root "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$logFile = Join-Path $logDir "install.log"
Start-Transcript -Path $logFile -Append

Write-Step "ComfyUI One-Click Installer (CUDA/NVIDIA)"

# --- Validate tools ---
Write-Step "Checking prerequisites"

if (!(Test-Command "git")) {
    throw "Git is not installed or not in PATH."
}
if (!(Test-Command "python")) {
    throw "Python is not installed or not in PATH."
}

python --version
git --version

# --- Setup folders ---
$comfyDir = Join-Path $root "ComfyUI"
$venvDir  = Join-Path $comfyDir "venv"
$nodesDir = Join-Path $comfyDir "custom_nodes"
$nodesListPath = Join-Path $root "installer\nodes.list"

# --- Install / update ComfyUI ---
Write-Step "Installing/Updating ComfyUI"

if (!(Test-Path $comfyDir)) {
    Write-Host "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git $comfyDir
} else {
    Write-Host "ComfyUI exists, pulling updates..."
    Set-Location $comfyDir
    git pull
}

# --- Create venv ---
Write-Step "Creating virtual environment"

Set-Location $comfyDir

if (!(Test-Path $venvDir)) {
    python -m venv venv
    Write-Host "venv created."
} else {
    Write-Host "venv already exists."
}

$py = Join-Path $venvDir "Scripts\python.exe"
$pip = Join-Path $venvDir "Scripts\pip.exe"

Write-Step "Upgrading pip"
& $py -m pip install --upgrade pip

# --- Install PyTorch CUDA ---
Write-Step "Installing PyTorch (CUDA build)"
& $pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# --- Install ComfyUI requirements ---
Write-Step "Installing ComfyUI requirements"
& $pip install -r (Join-Path $comfyDir "requirements.txt")

# --- Custom Nodes ---
Write-Step "Installing custom nodes"
New-Item -ItemType Directory -Force -Path $nodesDir | Out-Null

if (!(Test-Path $nodesListPath)) {
    Write-Host "No nodes.list found at: $nodesListPath"
    Write-Host "Skipping custom nodes."
} else {
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

        # If node contains requirements.txt, install it
        $req = Join-Path $target "requirements.txt"
        if (Test-Path $req) {
            Write-Host "Installing node requirements for $name"
            & $pip install -r $req
        }
    }
}

# --- Verification ---
Write-Step "Verification (Torch + CUDA)"
& $py -c "import torch; print('torch version:', torch.__version__); print('cuda available:', torch.cuda.is_available()); print('cuda device count:', torch.cuda.device_count())"

# --- Launch + Health Check ---
Write-Step "Launching ComfyUI and running health check"
Set-Location $comfyDir

$serverUrl = "http://127.0.0.1:8188/"
$logServer = Join-Path $logDir "comfyui-server.log"

# Start ComfyUI in background
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $py
$psi.Arguments = "main.py --listen 127.0.0.1 --port 8188"
$psi.WorkingDirectory = $comfyDir
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi

Write-Host "Starting ComfyUI..."
[void]$p.Start()

# Pipe stdout/stderr to a file
Start-Job -ScriptBlock {
    param($proc, $outfile)
    while (-not $proc.HasExited) {
        try {
            $o = $proc.StandardOutput.ReadLine()
            if ($o) { Add-Content -Path $outfile -Value $o }
        } catch {}
        try {
            $e = $proc.StandardError.ReadLine()
            if ($e) { Add-Content -Path $outfile -Value $e }
        } catch {}
        Start-Sleep -Milliseconds 50
    }
} -ArgumentList $p, $logServer | Out-Null

Write-Host "Waiting for ComfyUI at $serverUrl ..."
$ok = Wait-ForUrl $serverUrl 120

if (-not $ok) {
    try {
        if (-not $p.HasExited) { $p.Kill() }
    } catch {}
    throw "Health check FAILED: ComfyUI did not respond on port 8188. See logs/comfyui-server.log"
}

Write-Host "Health check PASSED: ComfyUI responded."

# Shutdown
Write-Host "Stopping ComfyUI..."
try {
    if (-not $p.HasExited) { $p.Kill() }
} catch {}

Write-Step "DONE"
Stop-Transcript
