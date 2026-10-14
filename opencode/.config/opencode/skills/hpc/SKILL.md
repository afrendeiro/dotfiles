---
name: hpc
description: Use ONLY when working with the CeMM HPC cluster — submitting SLURM jobs, checking queues, syncing code/data between local machine and HPC, or writing job scripts. Covers login, partitions, sbatch patterns, rsync workflow, and cluster conventions.
---

# HPC Cluster (CeMM)

## Critical Rules

### 1. NEVER delete any data

Do not use `rm`, `rm -rf`, `mv` (to overwrite), or any other destructive command on HPC files. Data is irreplaceable — there are no backups you can rely on. If you need to clean up, ask the user first.

### 2. NEVER compute on login nodes

The login nodes (`login`) are shared and must ONLY be used for:
- Submitting jobs (`sbatch`, `squeue`, `sinfo`, `scancel`)
- Light file inspection (`ls`, `wc`, `find`, `head`, `cat`)
- `rsync` transfers (these run on the source/destination nodes)
- Editing scripts with `vim`/`nano`

**Never** run Python, R, image processing, data analysis, or any computation directly on login nodes. Always use `sbatch`.

### 3. Stay in the project directory

Restrict all file operations to the current project directory (`~/projects/<name>/`). Never `cd` into system directories (`/`, `/etc`, `/tmp`, `/cm/`, etc.) or other users' project folders. Do not explore the filesystem outside the project at hand.

## Login

```bash
ssh -X $USER@login                   # hostname (requires CeMM network/VPN)
```

Local aliases (define in `~/.config/fish/conf.d/local.fish`):
```fish
alias hpc="ssh -X $USER@login"
```

**Local vs HPC username**: the local username may differ from the HPC one. Use the `login` host alias from `~/.ssh/config` (which sets `User`) instead of `$USER@login` in scripts and justfiles.

**Important**: Non-interactive SSH does not load SLURM. Always use `bash -l`:
```bash
ssh $USER@login 'bash -l -c "sinfo"'
```

SLURM binaries are at `/cm/shared/apps/slurm/current/bin/`.

## Partitions

| Partition | Time Limit | CPUs | Memory | GPU | Use Case |
|-----------|-----------|------|--------|-----|----------|
| `tinyq` | 2h | 24-48 | 1.5TB | L4 ×1 | Quick tests, debugging |
| `shortq` | 12h | 24-48 | 1.5TB | L4 ×1 | Short production runs |
| `mediumq` | 2d | 24-48 | 1.5TB | L4 ×1 | Medium-length jobs |
| `longq` | 30d | 48 | 1.5TB | none | Long CPU-only runs |
| `interactiveq` | 12h | 24-48 | 1.5TB | L4 ×1 | Interactive sessions |
| `gpu` (L4 nodes) | 3d | 24 | 1.5TB | L4, 1/node | Standard GPU |
| `gpu` (H100 PCIe nodes) | 3d | 64 | 500GB | H100, 2/node | Heavy GPU compute |
| `gpu` (H100 HGX node) | 3d | 64 | 2TB | H100, 4/node | Multi-GPU training |
| `develop` | 1h | 48 | 1.5TB | none | Development/debugging |
| `covid` | 20d | 24-48 | 1.5TB | L4 ×1 | COVID research (restricted) |

Node list: `d002` through `d035`. Use `sinfo` to check current availability.

## sbatch patterns

### GPU job (any GPU type)
```bash
sbatch \
  --job-name <project>.<task>.gpu.<id> \
  --partition=gpu --qos=gpu --gres=gpu:1 \
  --time 3-00:00:00 -c 8 --mem 128G \
  --comment="skip_dcgm" \
  --output logs/<task>/gpu.<id>.log \
  --wrap "uv run --frozen --no-sync python src/script.py"
```

For specific GPU types, replace `--gres=gpu:1` with:
- `--gres=gpu:h100pcie:1` — request 1 H100 PCIe GPU
- `--gres=gpu:h100pcie:2` — request 2 H100 PCIe GPUs
- `--gres=gpu:h100hgx:1` — request 1 of the 4 H100 HGX GPUs

### CPU job
```bash
sbatch \
  --partition=mediumq \
  --time 2-00:00:00 -c 8 --mem 64G \
  --output logs/<task>/cpu.<id>.log \
  --wrap "uv run --frozen --no-sync python src/analysis.py"
```

### Job array (for loop pattern)
```bash
for ID in {01..16}; do
  sbatch \
    --job-name <project>.processing.gpu.${ID} \
    --partition=gpu --qos=gpu --gres=gpu:1 --time 3-00:00:00 -c 8 --mem 128G \
    --comment="skip_dcgm" \
    --output logs/processing/gpu.${ID}.log \
    --wrap "uv run --frozen --no-sync python src/process.py"
done
```

### GRES (`--gres`) format

`--gres=gpu[:type]:<count>` — the last `:N` is always **how many GPUs**:

```bash
--gres=gpu:1               # 1 GPU of ANY type (L4, H100 PCIe, or H100 HGX)
--gres=gpu:2               # 2 GPUs of any type (must fit node's GPU count)
--gres=gpu:l4_gpu:1        # 1 L4 GPU specifically
--gres=gpu:h100pcie:1      # 1 H100 PCIe GPU
--gres=gpu:h100pcie:2      # 2 H100 PCIe GPUs (max on that node)
--gres=gpu:h100hgx:1       # 1 H100 HGX GPU
--gres=gpu:h100hgx:4       # all 4 H100 HGX GPUs on that node
```

**Prefer `--gres=gpu:1` without a type** unless you specifically need H100 PCIe or H100 HGX. It maximizes scheduling flexibility.

### Key flags summary
- `--gres=gpu:1` — 1 GPU of any type (most common, most flexible)
- `--qos=gpu` — required for GPU partition access
- `--comment="skip_dcgm"` — skips NVIDIA DCGM monitoring (standard for this cluster)
- `--mem` is per-node, not per-core
- `uv run --frozen --no-sync` — use the exact lockfile, don't touch the network

## Queue monitoring

```bash
sq                      # Shortcut: squeue filtered to your jobs
wsq                     # Watch your jobs continuously
squeue -o '%.6i %9P %50j %.10u %.2t %.10M %.6D %R'
sinfo                   # Partition/node availability
scancel <jobid>         # Cancel a job
sacct -S 2026-01-01 --user=$USER   # Job history
```

## Network and Python environment

- **All compute nodes have internet access**: downloads (e.g. public datasets) run inside SLURM jobs, not on the login node.
- **`uv` is installed on the HPC** at `~/.local/bin/uv`, which is only on `PATH` in interactive shells. In non-interactive ssh commands and job scripts, use `export PATH=$HOME/.local/bin:$PATH` (or call `~/.local/bin/uv`).
- Create/update the project environment **on the login node** with `uv sync --frozen` (uv can fetch managed Python versions), then run jobs with `uv run --frozen --no-sync ...`.
- The login node limits per-process memory: large environments (e.g. torch/CUDA wheels) make `uv sync` crash with `memory allocation ... failed`. Use low concurrency: `UV_CONCURRENT_DOWNLOADS=2 UV_CONCURRENT_INSTALLS=1 UV_CONCURRENT_BUILDS=1 uv sync --frozen`.

Example (from a local machine):
```bash
ssh login 'bash -l -c "export PATH=\$HOME/.local/bin:\$PATH UV_CONCURRENT_DOWNLOADS=2 UV_CONCURRENT_INSTALLS=1 && cd ~/projects/<name> && uv sync --frozen"'
```

## Code/data sync workflow

Code stays local, data stays on HPC. Use rsync (never git push/pull for working state).

### Push code to HPC
In `justfile`:
```make
sync-hpc:
    rsync -avz --exclude '.venv' --exclude '.git' --exclude '.ruff_cache' \
        --exclude 'data/' --exclude 'processed/' --exclude 'results/' \
        ./ $USER@login:~/projects/$(basename $(pwd))/
```

### Pull results from HPC
```make
fetch-processed:
    rsync -avz --progress \
        $USER@login:~/projects/$(basename $(pwd))/processed/analysis/ \
        ./processed/analysis/
```

### rsync version on the HPC

The HPC has rsync 3.1.3: options newer than that (e.g. `--mkpath`) fail with `unknown option`. Create destination parents with `ssh login 'mkdir -p ...'` first.

### rsync exclusion patterns
Always exclude from sync:
- `.venv/` — virtual environments
- `.git/` — version control (use git locally)
- `.ruff_cache/` — lint cache
- `data/` — large input data (stays on HPC)
- `processed/`, `results/` — output data (pull selectively)
- `__pycache__/`, `*.pyc` — Python cache

## Project paths on HPC

- Home: `$HOME/`
- Projects: `~/projects/<name>/` — this is the same as `~/nobackup/projects/<name>/` (the lab's shared projects storage on `~/nobackup/`). Code, data, processed outputs and results all live in the project directory.
- **Never use `~/scratch/`.**
- Logs: `~/projects/<name>/logs/`

## Project metadata: `cemm_metadata.json` (mandatory)

Every project root folder on the HPC (`~/projects/<name>/`) **must** contain a `cemm_metadata.json` that follows the CeMM metadata specification:

- Schema (JSON Schema draft-07): `https://metadata.int.cemm.at/latest/cemm_metadata_schema.json` (currently spec `1.0.0`; the file sets `"metadataSpecificationVersion": "1.0.0"` and `"schema": "http://metadata.int.cemm.at/1.0.0/cemm_metadata_schema.json"`).
- Required fields: `user`, `date`, `group`, `project`, `description`, `method`, `quality`, `rawOrProcessed`, `externalOrInternal`, `metadataSpecificationVersion`, `schema`. Use ontology terms for `method` (e.g. EFO), `organism` (NCBI Taxonomy) and `organTissueType` (UBERON), and verify the IDs (e.g. via EBI OLS).
- Set `metadataLocation` to the resolved path, e.g. `/nobackup/lab_rendeiro/projects/<name>/cemm_metadata.json`.
- Keep it in line with the data on disk: add a `date` entry for every data download/receipt or other data event.
- Always validate before syncing:
  ```bash
  curl -sk -o /tmp/cemm_metadata_schema.json https://metadata.int.cemm.at/latest/cemm_metadata_schema.json
  uvx check-jsonschema --schemafile /tmp/cemm_metadata_schema.json cemm_metadata.json
  ```
- Common pitfalls: trailing commas (invalid JSON), and empty strings in `format: date` fields (e.g. `"endDate": ""` fails — omit optional fields instead).
- Keep it at the root of the local project too, so it is synced with the code (`rsync` of the project root).

## Restricted (controlled-access) data

Because `~/nobackup/` is shared by the lab, controlled-access or otherwise sensitive data must be locked down:

- Layout per cohort: `data/<cohort>/` for openly available data, `data/<cohort>/restricted/` for controlled-access data of the same cohort.
- Permissions: restricted directories `700`, files `400` (`rsync --perms --chmod=D700,F400`, or `chmod -R u=rwX,go= <dir>` then `chmod 400` on files).
- Never copy restricted data outside its `restricted/` directory (no copies in scratch, home, shared group folders or results).

## Environment

The HPC uses `bash`. SLURM commands require `bash -l` to load. There is no `module` system — SLURM is at `/cm/shared/apps/slurm/current/bin/` and available in login shells.
