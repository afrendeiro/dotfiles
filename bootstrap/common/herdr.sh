#!/usr/bin/env bash
set -euo pipefail

if command -v herdr &>/dev/null; then
    echo "herdr already installed"
    exit 0
fi

curl -fsSL https://herdr.dev/install.sh | sh
