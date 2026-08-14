#!/usr/bin/env bash

if wlr-randr | grep -A 10 "^eDP-1" | grep -q "Enabled: yes"; then
    wlr-randr --output eDP-1 --off
    notify-send "Display" "Internal monitor disabled"
else
    wlr-randr --output eDP-1 --mode 1920x1200@120.000999 --scale 1.0 --pos 3840,0 --on
    notify-send "Display" "Internal monitor enabled"
fi
