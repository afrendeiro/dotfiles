#!/usr/bin/env bash
set -euo pipefail

echo "=== Hyprland-specific packages ==="
sudo pacman -S --noconfirm \
    hyprpicker \
    satty
