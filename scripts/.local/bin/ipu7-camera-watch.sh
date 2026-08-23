#!/usr/bin/env bash
# Keep the IPU7 camera relay always running, but frozen (SIGSTOP) while no
# app reads /dev/video33. A frozen producer keeps the v4l2loopback device
# "attached" (consumers can open and STREAMON without EIO) while the sensor
# stalls and its privacy LED stays off; SIGCONT resumes within milliseconds,
# so browsers never hit a cold-start race. v4l2loopback >= 0.15 emits no
# open/close uevents, so consumers are detected by scanning /proc fds.
# See notes/camera-ipu7.md.
set -u

DEV=/dev/video33
RELAY=ipu7-camera-relay.service
STOP_DELAY=15
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

systemctl --user start "$RELAY"
last_open=$(date +%s)
while true; do
    if [ -n "$(consumers)" ]; then
        systemctl --user kill -s SIGCONT "$RELAY" 2>/dev/null
        last_open=$(date +%s)
    elif systemctl --user is-active --quiet "$RELAY"; then
        now=$(date +%s)
        if [ $((now - last_open)) -ge "$STOP_DELAY" ]; then
            systemctl --user kill -s SIGSTOP "$RELAY" 2>/dev/null
        fi
    else
        systemctl --user start "$RELAY"
    fi
    sleep "$POLL_SEC"
done
