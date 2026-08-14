#!/usr/bin/env bash

INTERNAL="eDP-1"
EXTERNAL="DP-3"

lid_state=$(cat /proc/acpi/button/lid/LID0/state | awk '{print $2}')

if [ "$lid_state" == "closed" ]; then
    # Disable internal display, enable external
    hyprctl dispatch dpms off $INTERNAL
    hyprctl keyword monitor "$INTERNAL, disable"
    hyprctl keyword monitor "$EXTERNAL, preferred, auto, 1"
else
    # Lid open → enable internal again
    hyprctl keyword monitor "$INTERNAL, preferred, auto, 1"
    hyprctl keyword monitor "$EXTERNAL, preferred, auto, 1"
fi

