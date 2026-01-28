# ComfyUI NVIDIA CUDA Installer (ComfyUI + Custom Nodes)

This repository provides a **PowerShell-based installer** that automatically installs and configures:

- ✅ ComfyUI
- ✅ Python virtual environment (venv)
- ✅ PyTorch (CUDA build)
- ✅ ComfyUI dependencies
- ✅ Selected custom nodes + their requirements

> ⚠️ Note: This installer uses PowerShell + automated downloads and may be flagged by some antivirus solutions (heuristic detection). This is a common false-positive for automation scripts.

---

## What this installer contains

### Main installer script
- `installer/install.ps1`

### Custom nodes list
- `installer/nodes.list`

You can edit `nodes.list` to add/remove custom nodes (one GitHub repo per line).

---

## What will be installed

### Software / components
- **ComfyUI** (cloned from the official repo)
- **Python venv** created inside: `ComfyUI/venv`
- **PyTorch CUDA build**:
  - Installs: `torch`, `torchvision`, `torchaudio`
  - CUDA build: `cu121`
- **ComfyUI requirements**
- **Custom nodes listed in nodes.list**
  - Each node is installed into:
    - `ComfyUI/custom_nodes/<node_repo_name>/`
  - If a node contains `requirements.txt`, it will be installed automatically

### Current nodes installed (default)
- ComfyUI-Manager
- rgthree-comfy
- ComfyUI-SeedVR2_VideoUpscaler
- ComfyUI-KJNodes
- ComfyUI-Easy-Use
- ComfyUI-Impact-Pack
- ComfyUI-Inspire-Pack
- ComfyUI-GGUF

---

## Requirements

✅ Windows 10/11  
✅ NVIDIA GPU (CUDA) recommended  
✅ Git installed (or available in PATH)  
✅ Python installed (or available in PATH)

Suggested:
- NVIDIA driver installed and working
- At least 20–30 GB free disk space

---

## How to run the installer

### 1) Clone this repository
```bash
git clone https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
cd <YOUR_REPO>
