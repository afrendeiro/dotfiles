#!/usr/bin/env bash
set -euo pipefail

echo "=== GNOME-specific packages ==="
sudo pacman -S --noconfirm \
    gnome-browser-connector \
    xclip
