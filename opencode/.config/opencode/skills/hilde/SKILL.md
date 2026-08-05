---
name: hilde
description: Use ONLY when working with the Hilde GPU workstation — running deep learning jobs, checking GPU availability, managing shared caches, mounting the HPC filesystem, or booking resources. Covers SSH, hardware specs, shared UV/HuggingFace caches, monitoring, and maintenance.
---

# Hilde — Remote DL Workstation

Hilde is a Lambda Labs Vector GPU workstation for deep learning and GPU-accelerated computation.

## Login

```bash
ssh -X $USER@hilde.int.cemm.at        # hostname (requires CeMM network/VPN)
```

Local aliases (define in `~/.config/fish/conf.d/local.fish`):
```fish
alias hilde="ssh -X $USER@hilde.int.cemm.at"
```

## Hardware

- **GPU**: 2× NVIDIA RTX A6000 48GB (NVLink bridged)
- **CPU**: AMD Threadripper Pro 5975WX 3.6GHz (32 cores / 64 threads)
- **RAM**: 256GB (8× 32GB)
- **Disk**: 1× NVMe 3.5TB (system), 1× SATA SSD 3.6TB, 2× Samsung 990 Pro NVMe 3.6TB
- **Network**: 2× 10Gbps RJ45

Disk mountpoints:
- `/` — `/dev/nvme0n1p2` (system)
- `/data-nvme0` — `/dev/sda1`
- `/data-nvme1` — `/dev/nvme1n1p1`
- `/data-nvme2` — `/dev/nvme2n1p1`

## Shared caches

Hilde uses shared caches to save disk space. All users in `rendeirogroup` should configure these.

### UV cache

```bash
rm -rf ~/.cache/uv
ln -s /opt/uv_cache ~/.cache/uv
ls -la ~/.cache/ | grep uv    # Should show: uv -> /opt/uv_cache
```

### HuggingFace cache

```bash
rm -rf ~/.cache/huggingface
echo 'export HF_HUB_CACHE="/opt/hf_cache"' >> ~/.bashrc
echo 'unset HF_HOME' >> ~/.bashrc
source ~/.bashrc
```

Verify:
```bash
echo $HF_HUB_CACHE    # Should be: /opt/hf_cache
echo ${HF_HOME:-<unset>}  # Should be: <unset>
env -u HF_HOME hf auth login  # If HF_HOME is still set globally
```

## Project structure

All projects live under `/projects/<name>/`. Create your own directory there:
```bash
mkdir -p /projects/<project-name>
cd /projects/<project-name>
git clone <repo-url> .    # Or rsync from local
uv sync
```

## Monitoring

```bash
nvidia-smi                          # GPU status snapshot
watch -n 0.5 nvidia-smi             # Continuous GPU monitoring
gpustat                             # Condensed GPU status
htop                                # CPU and memory
dust /projects/                     # Disk usage per directory
```

## Mounting HPC filesystem

Access CeMM HPC files directly from Hilde:
```bash
mkdir -p /cluster/$USER
sshfs -o uid=$UID,gid=1004,default_permissions,follow_symlinks \
    $USER@login:/home/$USER /cluster/$USER
```

Files are then available at `/cluster/$USER/`. The `rendeirogroup` GID is 1004.

## Maintenance

A maintenance script is available at `hilde_workstation-maintenance`. It provides an interactive menu to:
- Check disk space and usage per user
- Clear caches (pip, PyTorch, HuggingFace, Docker)
- Check Docker images and prune unused resources
- Clean APT cache, temporary files, and trash folders
- Update the system

Full documentation: `~/work/labdocs/infrastructure/compute/gpu_workstation_hilde/gpu_workstation_hilde.md`

## Key rules

- Book the GPU/CPU before using it (Outlook calendar)
- Use the shared UV cache — do NOT create a local venv cache
- Use the shared HuggingFace cache — do NOT download models to your home directory
- Keep project code under `/projects/<name>/`
- Large data should go to `/data-nvme0/`, `/data-nvme1/`, or `/data-nvme2/` — not `/home/`
- Coordinate multi-GPU usage with the group
- The box runs Ubuntu Server with no GUI (headless)
