---
name: ty
description: Use ONLY when type-checking Python code or configuring the ty type checker (Astral's fast Rust-based type checker, companion to uv and ruff). Covers ty check invocation, pyproject.toml config, rule levels, suppression, and integration with ruff in scientific Python codebases.
---

# ty — Python type checker

ty is Astral's extremely fast Python type checker (Rust-based, 10x-100x faster than mypy/Pyright). It is a companion to uv and ruff from the same team.

ty is in beta (`0.0.x` versioning). Breaking changes, including new/changed diagnostics, may occur between versions.

## Core commands

```bash
ty check .                          # Type-check the project
ty check --watch .                  # Watch mode for continuous checking
ty check --rule <RULE> <LEVEL> .    # Override a specific rule level
ty check --select ALL .             # Enable all rules (see what's available)
ty check --json .                   # Machine-readable output
uvx ty check .                      # Run without installing (preferred for one-off use)
uv run ty check .                   # Run in project when ty is a dev dependency
```

## Configuration in pyproject.toml

```toml
[tool.ty]
# Target Python version
target-version = "py313"

# Rule configuration — set levels per rule
[tool.ty.rules]
# Disable or adjust specific rules
"possibly-unbound" = "error"
"redundant-cast" = "warn"

# Override rules per file/directory
[[tool.ty.overrides]]
include = ["tests/**/*.py"]
[tool.ty.overrides.rules]
"any-explicit" = "warn"      # Allow more any in tests

[[tool.ty.overrides]]
include = ["src/**/*.py"]
[tool.ty.overrides.rules]
"any-explicit" = "error"     # Stricter in production code
```

## Suppression comments

```python
x = some_untyped_call()  # ty: ignore — explanation of why
```

Use sparingly. Always include a brief justification after `—`.

## Relationship with ruff

- **ruff** handles: formatting (`ruff format`), linting (`ruff check`), import sorting
- **ty** handles: type checking only

Both should be run in CI/pre-commit:
```toml
# pyproject.toml or .pre-commit-config.yaml
# ruff for format + lint
# ty for type check
```

Common workflow: `ruff check . && ruff format --check . && ty check .`

## Gradual typing for scientific Python

Scientific code (single-cell, imaging, bioinformatics) often has partially-typed dependencies. ty supports gradual typing:

- Start with `ty check .` to see baseline errors
- Fix errors in the most critical code first (`src/<package>/ops.py`, `src/<package>/utils.py`)
- Use overrides to be stricter on library code, looser on scripts/tests
- Prefer `ty` over mypy — ty supports `redeclarations` and `partially typed code` which are common in scientific Python

## Known caveats (beta)

- ty is in `0.0.x` — expect churn in diagnostics and rule names between versions
- Pin the version in dev dependencies: `"ty>=0.0.65"`
- Check `https://docs.astral.sh/ty/` for latest rule documentation
- Some third-party libraries (torch, scanpy, etc.) may produce many false positives — use overrides to suppress those files/directories if needed
