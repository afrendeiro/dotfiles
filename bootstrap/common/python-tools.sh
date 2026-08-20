#!/usr/bin/env bash
set -euo pipefail

if ! command -v uv &>/dev/null; then
    echo "uv not found, run bootstrap/common/uv.sh first"
    exit 1
fi

uv tool install pyright
uv tool install ruff
uv tool install ty
uv tool install black
echo "python tools installed (pyright LSP, ruff linter, ty type checker, black formatter)"
