#!/usr/bin/env bash
# Move every (non-special) workspace to one display, toggling between the
# internal panel (eDP-1) and the external monitor. The target is whichever
# display currently holds fewer workspaces (ties go to the external), so
# repeated presses alternate — Hyprland always leaves one filler workspace on
# the emptied display, so "all on one display" is never literally true.
# The focused workspace stays focused.
#
# Usage: toggle-workspaces-display.sh

internal="eDP-1"

notify() { notify-send Workspaces "$1"; }

monitors="$(hyprctl monitors -j)"
external="$(jq -r --arg i "$internal" '[.[] | select(.name != $i and (.disabled | not))][0].name // empty' <<<"$monitors")"

if [ -z "$external" ]; then
    notify "No external display connected"
    exit 0
fi
if ! jq -e --arg i "$internal" 'any(.[]; .name == $i and (.disabled | not))' <<<"$monitors" >/dev/null; then
    notify "Internal display is off"
    exit 0
fi

workspaces="$(hyprctl workspaces -j | jq -c '[.[] | select(.name | startswith("special:") | not)]')"

if jq -e --arg e "$external" '(map(select(.monitor == $e)) | length) > length / 2' <<<"$workspaces" >/dev/null; then
    target="$internal"
else
    target="$external"
fi

focused="$(hyprctl activeworkspace -j | jq -r '.name')"

# Numbered workspaces are addressed by id, named ones as "name:<name>".
selector() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then printf '%s' "$1"; else printf 'name:%s' "$1"; fi
}

jq -r --arg t "$target" '.[] | select(.monitor != $t) | .name' <<<"$workspaces" |
    while IFS= read -r name; do
        hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$(selector "$name")\", monitor = \"$target\" })" >/dev/null
    done

hyprctl dispatch "hl.dsp.focus({ workspace = \"$(selector "$focused")\" })" >/dev/null

notify "All workspaces moved to $target"
