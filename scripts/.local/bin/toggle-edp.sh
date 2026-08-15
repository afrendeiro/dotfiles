#!/usr/bin/env bash

if [ "$(hyprctl monitors all -j | jq -r '.[] | select(.name == "eDP-1") | .disabled')" = "false" ]; then
    wlr-randr --output eDP-1 --off
    notify-send "Display" "Internal monitor disabled"
else
    wlr-randr --output eDP-1 --on
    notify-send "Display" "Internal monitor enabled"
fi

# Re-evaluate PRIMARY_MONITOR and workspace monitor bindings for the new layout
sleep 0.5
hyprctl reload
