#!/bin/sh

state_file="${XDG_RUNTIME_DIR:-/tmp}/imv-bg-$imv_pid"

if [ "$(cat "$state_file" 2>/dev/null)" = "white" ]; then
    color="000000"
    next="dark"
else
    color="ffffff"
    next="white"
fi

if imv-msg "$imv_pid" background "$color"; then
    echo "$next" > "$state_file"
fi
