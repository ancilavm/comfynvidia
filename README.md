# ComfyUI NVIDIA CUDA Installer (ComfyUI + Custom Nodes)

> **⚠️ NVIDIA ONLY:** This installer is designed for **NVIDIA GPUs with CUDA**.  
> It installs the **CUDA-enabled PyTorch build (cu121)** and is **not intended for AMD GPUs**.

This repository provides a **PowerShell installer** that automatically installs **ComfyUI**, **CUDA PyTorch**, and a curated set of **custom nodes**.

It is intended for Windows users who want a reproducible setup without manually editing `.bat` files each time.

---

## What this installer does

When you run the installer, it will:

✅ Clone / update ComfyUI  
✅ Automatically install **Python** (if missing)  
✅ Automatically install **Git** (if missing)  
✅ Create a Python virtual environment (`venv`)  
✅ Install **PyTorch CUDA build (cu121)**  
✅ Install ComfyUI requirements  
✅ Install custom nodes from a list  
✅ Install node requirements (if `requirements.txt` exists in the node repo)  
✅ Run a health check (on real machines) by launching ComfyUI and checking port 8188  

---

## Repository contents

### Installer script
- `installer/install.ps1`

### Custom nodes list (editable)
- `installer/nodes.list`

### Install command helper file
- `how_to_install.txt` (contains the install command)

---

## Default custom nodes included

The installer installs these nodes by default (from `installer/nodes.list`):

- ComfyUI-Manager — https://github.com/Comfy-Org/ComfyUI-Manager
- rgthree-comfy — https://github.com/rgthree/rgthree-comfy
- ComfyUI-SeedVR2_VideoUpscaler — https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler
- ComfyUI-KJNodes — https://github.com/kijai/ComfyUI-KJNodes
- ComfyUI-Easy-Use — https://github.com/yolain/ComfyUI-Easy-Use
- ComfyUI-Impact-Pack — https://github.com/ltdrdata/ComfyUI-Impact-Pack
- ComfyUI-Inspire-Pack — https://github.com/ltdrdata/ComfyUI-Inspire-Pack
- ComfyUI-GGUF — https://github.com/city96/ComfyUI-GGUF

---

## Requirements

### System
- Windows 10 / Windows 11
- **NVIDIA GPU required (CUDA)**

### Software (IMPORTANT)
✅ You do **NOT** need to install Git or Python manually.  
The installer will automatically install them if missing.

### Permissions
⚠️ For first-time installation (when Git/Python are missing), you must run PowerShell as:

✅ **Run as Administrator**

Minimum recommended hardware:
- 8GB VRAM (more is better)
- 16GB RAM (32GB recommended)
- 20–40 GB free disk space (depends on models)

---

# Installation Instructions

You can install in two ways:

---

## Option A — Download ZIP (easiest)

1) Open this repo:
https://github.com/ancilavm/comfyui-oneclick-installer

2) Click:
**Code → Download ZIP**

3) Extract the ZIP

4) Open PowerShell inside the extracted folder

5) Run the installer command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File installer\install.ps1
