#!/usr/bin/env bash
# Toggle the internal panel (eDP-1).
#
# The desired state is persisted in ${XDG_STATE_HOME:-~/.local/state}/edp-state
# ("on"/"off") and read by hyprland/config/monitors.lua: Hyprland re-applies
# monitor rules on every config reload, so without the state file the panel
# would come back on (this script's own reload, noctalia's colors_changed hook,
# ...). Usage: toggle-edp.sh [on|off|toggle]  (default: toggle)

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/edp-state"
mkdir -p "${STATE%/*}"

action="${1:-toggle}"
if [ "$action" = "toggle" ]; then
    if [ "$(hyprctl monitors all -j | jq -r '.[] | select(.name == "eDP-1") | .disabled')" = "false" ]; then
        action="off"
    else
        action="on"
    fi
fi

case "$action" in
    on|off) ;;
    *)
        echo "usage: $0 [on|off|toggle]" >&2
        exit 2
        ;;
esac

printf '%s\n' "$action" > "$STATE"

# Reload applies the state via monitors.lua and re-evaluates PRIMARY_MONITOR
# and the workspace monitor bindings for the new layout.
hyprctl reload
notify-send "Display" "Internal monitor ${action}"
