#!/usr/bin/env bash

# --- Configuration ---
INTERNAL="eDP-1"
EXTERNAL="DP-3"

# --- Helper: Force refresh displays with DPMS ---
force_refresh() {
    hyprctl dispatch dpms off
    sleep 0.5
    hyprctl dispatch dpms on
}

# --- Main monitor logic ---
set_monitors() {
    if hyprctl monitors | grep -q "$EXTERNAL"; then
        # ✅ External connected
        hyprctl keyword monitor "$INTERNAL, disable"
        sleep 0.5
        hyprctl keyword monitor "$EXTERNAL, preferred, auto, 1"
        notify-send "Hyprland" "External monitor ($EXTERNAL) active — laptop screen off"
    else
        # ⚙️ External disconnected
        sleep 1.5  # allow Hyprland to re-detect internal
        hyprctl keyword monitor "$INTERNAL, preferred, auto, 1"
        sleep 0.5
        hyprctl keyword monitor "$EXTERNAL, disable"
        force_refresh   # 🔄 ensure the laptop display lights up again
        notify-send "Hyprland" "External monitor disconnected — laptop screen on"
    fi
}

# --- Initial setup on login ---
set_monitors

# --- Listen for hotplug events ---
hyprctl -i events | while read -r line; do
    if echo "$line" | grep -q "monitoradded"; then
        sleep 1
        set_monitors
    elif echo "$line" | grep -q "monitorremoved"; then
        sleep 2
        set_monitors
    fi
done
