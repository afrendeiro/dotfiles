---
name: uv
description: Use ONLY when working with Python projects that use uv for package management, dependency resolution, virtual environments, or project initialization. Covers uv sync, uv run, uv add, uv lock, uv init, uv pip, uvx, dependency groups, build backends, and HPC-specific uv patterns.
---

# uv — Python package & project manager

uv is Astral's fast Python package manager (Rust-based). This project uses uv exclusively — no pip, no poetry, no conda.

## Core commands

```bash
uv sync              # Install all deps (uses uv.lock if present, pyproject.toml otherwise)
uv sync --frozen     # Install exact versions from uv.lock without updating it
uv run python script.py    # Run Python in the venv
uv run --with ipython ipython  # Run a tool with an extra dep
uv add pandas        # Add a runtime dependency
uv add --dev ruff    # Add a dev dependency (goes into [dependency-groups].dev)
uv remove pandas     # Remove a dependency
uv lock              # Lock deps and regenerate uv.lock
uv lock --upgrade    # Upgrade all deps and regenerate uv.lock
uv lock --upgrade-package pandas  # Upgrade a single package
uv init [path]       # Create a new project (defaults to --build-backend uv since 0.12.0)
uv init --lib        # Create a library package (src layout)
uv init --app        # Create an application (flat layout)
uv init --script     # Create a single-file script with inline metadata
uv pip list          # List installed packages in the venv
uv pip install -e .  # Editable install (for legacy workflows; use uv sync normally)
uv tree              # Show dependency tree
uv python list       # Show available/managed Python versions
uv tool install ruff # Install a tool globally
uv tool run ruff     # Run a tool (or use uvx)
uvx ruff check .     # Run a tool without installing (shorthand for uv tool run)
```

## Project config conventions

### pyproject.toml structure (PEP 621)

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "..."
readme = "README.md"
requires-python = ">=3.13"
dependencies = ["pandas>=2.0", ...]

[dependency-groups]
dev = ["ruff>=0.11", "ty>=0.0.65", "pytest>=8.0", "ipython>=9.0"]

[build-system]
requires = ["uv_build>=0.12.0,<0.13.0"]
build-backend = "uv_build"

[tool.uv]
prerelease = "allow"     # Only if you need pre-release package versions

[tool.uv.sources]
conch = { git = "https://github.com/mahmoodlab/CONCH.git" }  # Git dependencies
```

### Build backend: uv_build (default since uv 0.12.0)

New projects should use `uv_build` (no extra build dependency; uv handles building natively):
```toml
[build-system]
requires = ["uv_build>=0.12.0,<0.13.0"]
build-backend = "uv_build"
```

Older projects may use `hatchling` — either pattern works; prefer `uv_build` for new projects.

### .python-version

Always commit `.python-version`. It pins the Python version for the project:
```
3.13
```

### uv.lock

Always commit `uv.lock`. It ensures reproducible installs across machines (local, HPC, Hilde).

## Dependency groups

Dev-only deps go in `[dependency-groups]`, not `[project].dependencies`:
```toml
[dependency-groups]
dev = ["ruff", "ty", "pytest", "ipython", "pre-commit"]
```

Install with: `uv sync` (default includes dev), `uv sync --no-dev` (production only).

## Self-contained scripts (uv inline metadata)

For standalone scripts that should work without a project:

```python
# /// script
# requires-python = ">=3.13"
# dependencies = ["pandas", "matplotlib"]
# ///
import pandas as pd
df = pd.read_csv("data.csv")
```

Run with: `uv run script.py` (uv auto-detects inline metadata).

## HPC-specific patterns

On the HPC cluster, SLURM commands are in `/cm/shared/apps/slurm/current/bin/` and require `bash -l`.

For sbatch job scripts, use `--frozen --no-sync` to avoid touching the network:
```bash
uv run --frozen --no-sync python src/analysis.py
```

This ensures the exact same environment as local development.

## Key rules

- **Never** use `pip install` directly — always `uv add` or `uv pip`
- **Never** manually edit `uv.lock` — use `uv lock`
- Commit `.python-version` and `uv.lock` to version control
- `.venv/` should be in `.gitignore` and excluded from rsync
- Use `uv run` (not `python`) to run scripts within a project
- For tools that aren't project deps, use `uvx` (e.g., `uvx ruff check .`, `uvx ty check`)
