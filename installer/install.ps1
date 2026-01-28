# installer/install.ps1
# ComfyUI NVIDIA CUDA Installer (ComfyUI + Custom Nodes)
#
# Requirements:
# - Git must be installed (user installs it manually to clone this repo)
# - Python will be installed automatically if missing
#
# What it does:
# - Installs/updates ComfyUI
# - Creates venv
# - Installs CUDA PyTorch cu121
# - Installs requirements and custom nodes
# - Installs InsightFace (prebuilt wheel, no C++ build tools)
# - Optional: Configure external Models folder via extra_model_paths.yaml
# - Creates run_comfyui.bat and update_comfyui.bat

$ErrorActionPreference = "Stop"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "=== $msg ==="
}

function Test-Com
