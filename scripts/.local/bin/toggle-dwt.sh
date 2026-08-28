#!/usr/bin/env bash
# Toggle Hyprland touchpad "disable while typing" (DWT) — useful for games
# where holding keys (WASD) suppresses touchpad look.

state="$(hyprctl getoption input:touchpad:disable_while_typing -j | jq -r '.bool')"
if [ "$state" = "true" ]; then
    hyprctl eval 'hl.config({ input = { touchpad = { disable_while_typing = false } } })' >/dev/null
    notify-send -a hyprland "Touchpad DWT" "disabled (touchpad stays live while typing)"
else
    hyprctl eval 'hl.config({ input = { touchpad = { disable_while_typing = true } } })' >/dev/null
    notify-send -a hyprland "Touchpad DWT" "enabled"
fi
