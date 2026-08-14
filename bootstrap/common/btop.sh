#!/usr/bin/env bash
set -euo pipefail

# Build btop from deveworld/btop PR #1457 branch (feature/xe-gpu-support)
# which adds Intel Xe driver GPU monitoring (fdinfo/gtidle/DRM). Stock btop
# only supports the i915 PMU and cannot detect Xe GPUs (e.g. Panther Lake,
# Lunar Lake, Battlemage).
# Tracks the installed build commit in ~/.local/state/btop-xe-commit and
# rebuilds when the pinned branch moves.

SRC=$HOME/clones/btop
BIN=$HOME/.local/bin/btop
FORK=https://github.com/deveworld/btop.git
BRANCH=feature/xe-gpu-support
MARK=$HOME/.local/state/btop-xe-commit

if [ ! -d "$SRC" ]; then
    git clone --branch "$BRANCH" "$FORK" "$SRC"
else
    git -C "$SRC" fetch origin "$BRANCH"
    git -C "$SRC" reset --hard "origin/$BRANCH"
fi

COMMIT=$(git -C "$SRC" rev-parse --short HEAD)
if [ ! -x "$BIN" ] || [ "$(cat "$MARK" 2>/dev/null || true)" != "$COMMIT" ]; then
    make -C "$SRC" clean
    make -C "$SRC" GPU_SUPPORT=true -j"$(nproc)"
    make -C "$SRC" install PREFIX="$HOME/.local"
    echo "$COMMIT" > "$MARK"
fi
