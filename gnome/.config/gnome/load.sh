#!/usr/bin/env bash
set -euo pipefail

DIR="$(dirname "$(readlink -f "$0")")/dconf"
SCHEMAS=(
  "wm-keybindings.dconf          /org/gnome/desktop/wm/keybindings/"
  "shell-keybindings.dconf       /org/gnome/shell/keybindings/"
  "media-keys.dconf              /org/gnome/settings-daemon/plugins/media-keys/"
)

for entry in "${SCHEMAS[@]}"; do
  file="${entry%% *}"
  schema="${entry##* }"
  if [[ -f "$DIR/$file" ]]; then
    echo "Loading $file"
    sed "s|/home/afr|$HOME|g" "$DIR/$file" | dconf load "$schema"
  else
    echo "Skipping $file (not found)"
  fi
done
echo "Done. Keybindings should take effect immediately on Wayland."
