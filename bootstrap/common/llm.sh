#!/usr/bin/env bash
set -euo pipefail

if ! command -v uv &>/dev/null; then
    echo "uv not found, run bootstrap/common/uv.sh first"
    exit 1
fi

uv tool install llm
llm install llm-deepseek
echo "Set your DeepSeek key with: llm keys set deepseek"
