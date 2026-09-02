#!/bin/sh
# Toggle Hyprland-side sleep-on-lid-close (lid.lua reads this state).
# Flag content "disabled" = lid close does NOT suspend (battery, no
# external monitor); anything else (or missing) = suspend. No root, no
# logind involvement — never restart systemd-logind from a running
# session (kills the uwsm/Hyprland session → black screen).

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/lid-suspend"
mkdir -p "${STATE%/*}"

if [ "$(cat "$STATE" 2>/dev/null)" = "disabled" ]; then
    echo "enabled" > "$STATE"
    notify-send -a hyprland "Lid close" "sleep: on (suspend on battery)"
else
    echo "disabled" > "$STATE"
    notify-send -a hyprland "Lid close" "sleep: off"
fi
