---
name: coding-style
description: Use when writing, editing, or reviewing Python code — especially for computational biology, single-cell analysis, or imaging projects. Covers project structure, tooling, script organization, output formats, and coding conventions used by this developer.
---

# Coding Style

## Project setup

### New projects

Use `cookiecutter` for research projects:
```bash
newproject    # alias for: cookiecutter gh:rendeirolab/_project_template
```

Or create manually with uv:
```bash
uv init my-project
cd my-project
echo "3.13" > .python-version
uv add pandas matplotlib numpy scipy  # add actual deps
uv add --dev ruff ty pytest ipython
```

### Build backend

Since uv 0.12.0, the default build backend is `uv_build` (not hatchling):
```toml
[build-system]
requires = ["uv_build>=0.12.0,<0.13.0"]
build-backend = "uv_build"
```
No extra build dependency needed — uv handles building natively.

### Minimal pyproject.toml skeleton
```toml
[project]
name = "my-project"
version = "0.1.0"
description = "..."
readme = "README.md"
requires-python = ">=3.13"
dependencies = ["pandas>=2.0", "numpy>=2.0"]

[build-system]
requires = ["uv_build>=0.12.0,<0.13.0"]
build-backend = "uv_build"

[dependency-groups]
dev = ["ruff", "ty", "pytest", "ipython"]

[tool.uv]
prerelease = "allow"    # Only if needed
```

## Tooling

| Tool | Purpose | How to run |
|------|---------|------------|
| **uv** | Package management, venv, Python versions | `uv sync`, `uv run`, `uv add` |
| **ruff** | Formatting + linting | `uv run ruff format .`, `uv run ruff check .` |
| **ty** | Type checking | `uv run ty check .` |
| **pytest** | Testing | `uv run pytest` |
| **just** | Task runner | `just <recipe>` |

### justfile (preferred over taskipy/make)

Use `just` for project tasks. It's a command runner with better syntax than Make:
```make
# justfile
_uv := "uv"

sync-hpc:
    rsync -avz --exclude '.venv' --exclude '.git' --exclude '.ruff_cache' \
        --exclude 'data/' --exclude 'processed/' --exclude 'results/' \
        ./ $USER@login:~/projects/$(basename $(pwd))/

fetch-processed:
    rsync -avz --progress \
        $USER@login:~/projects/$(basename $(pwd))/processed/analysis/ \
        ./processed/analysis/

analyze model="default" harmony="--harmony":
    {{_uv}} run python src/analysis/run_analysis.py --model {{model}} {{harmony}}

fmt:
    {{_uv}} run ruff format src/ tests/
    {{_uv}} run ruff check --fix src/ tests/

test:
    {{_uv}} run pytest tests/

clean:
    find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name '*.pyc' -delete 2>/dev/null || true
```

Named variables (`{{model}}`, `{{date}}`) make recipes reusable.

## Project structure

### Research project layout
```
my-project/
├── pyproject.toml        # PEP 621 project metadata + tool config
├── uv.lock               # Locked dependencies (committed)
├── .python-version        # Python version pin (committed)
├── justfile              # Task recipes
├── matplotlibrc          # Matplotlib defaults (optional but recommended)
├── README.md             # Project overview
├── METHODS.md            # Detailed methodology
├── RESULTS.md            # Results narrative
├── src/
│   ├── <package>/        # Library code
│   │   ├── __init__.py
│   │   ├── utils.py      # Shared helper functions, plotting, style
│   │   └── ops.py        # Core operations, algorithms, pipelines
│   ├── analysis/         # Analysis scripts
│   │   ├── unsupervised_analysis.py
│   │   └── effect_analysis.py
│   ├── preprocessing/    # Data preprocessing scripts
│   │   └── build_annotation.py
│   └── processing/       # Data processing scripts (often run on HPC)
│       └── process_lz.py
├── data/                 # Input data (not synced to HPC, in .gitignore)
├── processed/            # Intermediate results
├── results/              # Final results mirroring src/ structure
│   └── analysis/
│       └── <model>/
│           └── unsupervised_harmony/
│               ├── dimred_raw.svg
│               └── clusters.csv
└── reports/              # Final reports per date
    └── 2026-01-01/
        ├── figures/
        ├── analysis_summary.md
        └── analysis_summary.html
```

### Key structural rules

- **Scripts are self-contained**: each `src/*/*.py` file is an independent pipeline step, runnable via `uv run python src/<category>/<script>.py`
- **Library code in package**: shared logic lives in `src/<package>/utils.py` (helpers, plotting) and `ops.py` (algorithms, pipelines)
- **Output mirrors source**: results directory structure mirrors the script that produced them
  - `src/analysis/unsupervised_analysis.py` → `results/analysis/<model>/unsupervised_harmony/`
- **Scripts use CLI args** (via `argparse` or `click`), not hardcoded paths or config files
- **`justfile` is the interface**: all common operations are just recipes, not shell scripts

## Output conventions

- **CSV, parquet** for tabular data (never Excel as primary format)
- **SVG** for figures (never PNG as primary; convert to PNG for reports)
- **h5ad** for single-cell data (AnnData)
- **zarr** for large arrays (when appropriate)
- **Results are dated** or model-named for provenance

```python
# In analysis scripts
results_dir = Path("results/analysis") / model / analysis_name
fig_dir = results_dir / "figures"  # if extra figures
results_dir.mkdir(parents=True, exist_ok=True)
df.to_csv(results_dir / "effect_sizes.csv", index=False)
fig.savefig(results_dir / "dimred_raw.svg")
```

## Matplotlib style

Use a `matplotlibrc` file at the project root for consistent plot settings:
```
savefig.dpi: 300
savefig.bbox: tight
font.size: 8
axes.labelsize: 9
axes.titlesize: 9
legend.fontsize: 7
xtick.labelsize: 7
ytick.labelsize: 7
```

Palettes go in `utils.py` as module-level constants:
```python
GROUP_PALETTE = {"Control": "#377eb8", "Treatment": "#4daf4a"}
TISSUE_PALETTE = {"Brain": "#1f77b4", "Kidney": "#ff7f0e", ...}
```

## Type annotations

- Use in library code (`utils.py`, `ops.py`) — these are reused across scripts
- Scripts (`src/analysis/*.py`, `src/processing/*.py`) can be more relaxed
- Use `ty` for type checking (faster than mypy, integrates with uv/ruff)
- Configure per-file strictness in `[tool.ty.overrides]` (see ty skill)

## Imports

ruff handles import sorting. Standard order:
1. Standard library (`pathlib`, `os`, `sys`)
2. Third-party (`numpy`, `pandas`, `scanpy`, `matplotlib`)
3. Local (`from <package>.utils import ...`)

## Documentation

- `README.md`: project overview, quickstart
- `METHODS.md`: detailed methodology, computational steps, parameters
- `RESULTS.md`: narrative of findings, figure references
- Docstrings: use for public API functions in `utils.py`/`ops.py`, keep scripts lightweight

## .gitignore essentials

```
.venv/
__pycache__/
*.pyc
.ruff_cache/
.ipynb_checkpoints/
data/
processed/
results/
reports/
.DS_Store
```

## HPC code patterns

- Code runs identically on local and HPC: `uv run --frozen --no-sync python src/<script>.py`
- Data paths use environment variables or CLI args, never hardcoded absolute paths
- Log output goes to `logs/<task>/` on HPC, organized by task name
