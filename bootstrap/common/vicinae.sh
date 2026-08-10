#!/usr/bin/env bash
set -euo pipefail

if command -v vicinae &>/dev/null; then
    echo "vicinae already installed"
    exit 0
fi

curl -fsSL https://vicinae.com/install | bash
