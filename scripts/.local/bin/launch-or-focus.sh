#!/usr/bin/env bash
# Focus an existing window by class/app_id (on any workspace), or launch the
# given command. Class matching is case-insensitive.
#
# Usage: launch-or-focus.sh <window-class> <command...>

class="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"; shift

addr="$(hyprctl clients -j | jq -r --arg c "$class" \
    '.[] | select((.class // "" | ascii_downcase) == $c or (.initialClass // "" | ascii_downcase) == $c) | .address' \
    | head -n1)"

if [ -n "$addr" ]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:${addr}\" })"
else
    exec "$@"
fi
