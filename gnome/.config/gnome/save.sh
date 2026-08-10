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
  echo "Saving $file"
  dconf dump "$schema" | sed "s|$HOME|/home/afr|g" > "$DIR/$file"
done
echo "Done. Stowed .dconf files updated from current GNOME settings."
