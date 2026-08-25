#!/usr/bin/env bash

systemctl --user restart pipewire pipewire-pulse wireplumber

# Restarting pipewire drops noctalia's in-process WirePlumber mixer connection
# (no reconnection logic), so volume/mute keys would silently stop working.
# Relaunch it so it reconnects to the fresh daemon.
if pgrep -x Hyprland >/dev/null 2>&1; then
    pkill noctalia 2>/dev/null
    sleep 1
    nohup noctalia >/dev/null 2>&1 &
fi
