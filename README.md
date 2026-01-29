# ComfyNVIDIA — ComfyUI NVIDIA CUDA Installer (Windows)

> **⚠️ NVIDIA ONLY:** This installer is designed for **Windows + NVIDIA GPUs with CUDA**.  
> It installs the **CUDA-enabled PyTorch build (cu121)** and is **not intended for AMD GPUs**.

This repository provides an automated **PowerShell installer** that sets up ComfyUI with CUDA PyTorch, curated custom nodes, **InsightFace**, and optional shared external Models folder support.

---

## What this installer will do

When you run the installer, it will:

✅ Clone / update ComfyUI  
✅ **Install / enforce Python 3.11** (recommended for ComfyUI stability and custom node compatibility)  
✅ Create a Python virtual environment (`venv`) for ComfyUI  
✅ Install **PyTorch CUDA build (cu121)**  
✅ Install ComfyUI requirements  
✅ Install custom nodes listed in `installer/nodes.list`  
✅ Install node requirements automatically (if node has `requirements.txt`)  
✅ Install **InsightFace** (prebuilt wheel, no C++ build tools)  
✅ Ask for an existing Models folder path and generate `ComfyUI\extra_model_paths.yaml`  
✅ Create helper files:  
- `run_comfyui.bat` → starts ComfyUI  
- `update_comfyui.bat` → updates ComfyUI + all custom nodes  

---

## Requirements (IMPORTANT)

### System
- Windows 10 / Windows 11
- **NVIDIA GPU required (CUDA)**
- NVIDIA GPU drivers installed

### Git (Required)
Git is required because this repo is installed using `git clone`.

✅ Install Git first:  
https://git-scm.com/downloads

Verify Git works:

```bash
git --version
```

### Python
❗ You do **NOT** need to install Python manually.

✅ The installer will install/enforce **Python 3.11** automatically (via winget).

---

# Installation Instructions

## Step 1 — Install Git
Download and install Git first:  
https://git-scm.com/downloads

Restart CMD/PowerShell and confirm:

```bash
git --version
```

---

## Step 2 — Clone this repo
Open **CMD** and run:

```bash
git clone https://github.com/ancilavm/comfynvidia.git
cd comfynvidia
```

---

## Step 3 — Run the installer (PowerShell)

From the repo folder, open PowerShell and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\install.ps1
```

---

## During installation (interactive prompts)

The installer will ask you:

### 1) Install InsightFace?
- Recommended: **YES**
- InsightFace is used by FaceID / InsightFace-based workflows and nodes
- Installed using prebuilt `.whl` (no compiling / no C++ build tools)

### 2) Link an existing Models folder?
If you already have models stored on another drive (example: `D:\AI\Models`), select YES.

Installer will generate:

```
ComfyUI\extra_model_paths.yaml
```

so this ComfyUI install can access your existing Models folder.

> Your Models folder may contain subfolders like:
> `checkpoints`, `loras`, `vae`, `controlnet`, `clip`, `clip_vision`, `upscale_models`, `embeddings`, etc.

---

# After Installation

## Start ComfyUI
Double click:

✅ `run_comfyui.bat`

Or start manually:

```powershell
cd .\ComfyUI
.\venv\Scripts\python.exe main.py --listen 127.0.0.1 --port 8188
```

Open in browser:

http://127.0.0.1:8188

---

## Update ComfyUI + Custom Nodes
Double click:

✅ `update_comfyui.bat`

This updates:
- ComfyUI (`git pull`)
- each custom node in `ComfyUI\custom_nodes\` (`git pull`)

---

## Custom Nodes List

Custom nodes installed are defined here:

```
installer\nodes.list
```

Rules:
- One GitHub repo URL per line
- Empty lines allowed
- Lines starting with `#` are ignored

---

## Logs

All logs are written to:

```
logs\
```

### Installer log
- `logs\install.log`

### ComfyUI server log
- `logs\comfyui-server.log`

---

## Troubleshooting

### 1) Git not found
If you see errors like `git is not recognized`, install Git:

https://git-scm.com/downloads

Restart CMD/PowerShell and run again.

---

### 2) winget not found / Python install fails
This installer installs Python 3.11 using **winget**.

If winget is missing or disabled:
- install Python 3.11 manually from: https://www.python.org/downloads/windows/
- restart your PC
- run installer again

---

### 3) Health check failed / Port 8188 not responding
Run ComfyUI manually to see the full error output:

```powershell
cd .\ComfyUI
.\venv\Scripts\python.exe main.py --listen 127.0.0.1 --port 8188
```

---

### 4) External Models folder gives "Access denied"
Choose a folder that your Windows account can access (example: `D:\AI\Models`).  
Avoid protected system folders.

---

## Notes

- This installer is designed for **NVIDIA CUDA environments only**
- Models are **NOT downloaded automatically**
- You must place models inside your Models folder (or ComfyUI models folder)

---

## Disclaimer
This installer downloads and installs third-party software (Python packages and Git repositories).  
Git must be installed manually before running this installer. Use at your own risk.
