#!/usr/bin/env bash
# Keep the IPU7 camera relay running only while something actually reads
# /dev/video33, so the sensor (and its privacy LED) is off when unused.
# v4l2loopback emits no open/close uevents (0.15.x), so detect consumers by
# scanning /proc fds. See notes/camera-ipu7.md.
set -u

DEV=/dev/video33
RELAY=ipu7-camera-relay.service
STOP_DELAY=5
POLL_SEC=0.5

relay_pid() {
    systemctl --user show -p MainPID --value "$RELAY" 2>/dev/null
}

consumers() {
    local pid relay_pid
    relay_pid="$(relay_pid)"
    for pid in $(lsof -t "$DEV" 2>/dev/null); do
        if [ -n "$relay_pid" ] && [ "$pid" = "$relay_pid" ]; then
            continue
        fi
        if [ -d "/proc/$pid" ]; then
            echo "$pid"
        fi
    done
}

closed_since=0
while true; do
    if [ -n "$(consumers)" ]; then
        systemctl --user start "$RELAY"
        closed_since=$(date +%s)
    elif systemctl --user is-active --quiet "$RELAY"; then
        now=$(date +%s)
        if [ $((now - closed_since)) -ge "$STOP_DELAY" ]; then
            systemctl --user stop "$RELAY"
        fi
    fi
    sleep "$POLL_SEC"
done
