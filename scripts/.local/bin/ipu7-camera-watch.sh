#!/usr/bin/env bash
# Give browsers/apps the IPU7 camera without keeping the sensor (and its
# privacy LED) running while idle.
#
# ipu7-camera-proxy.service always writes a black 720p frame stream to
# /dev/video33, so the loopback always has a producer attached and consumers
# never hit the EIO/EBUSY cold-start race (STREAMON succeeds immediately).
# While any app reads the device, this watchdog swaps the proxy for
# ipu7-camera-relay.service (the real libcamera sensor); when the device has
# stayed unread for STOP_DELAY seconds it swaps back, so the sensor/LED only
# runs while the camera is actually used. v4l2loopback >= 0.15 emits no
# open/close uevents, so consumers are detected by scanning /proc fds.
# See notes/camera-ipu7.md.
set -u

DEV=/dev/video33
RELAY=ipu7-camera-relay.service
PROXY=ipu7-camera-proxy.service
STOP_DELAY=15
POLL_SEC=0.5
SWAP_WAIT=1

consumers() {
    local pid comm
    for pid in $(lsof -t "$DEV" 2>/dev/null); do
        [ -d "/proc/$pid" ] || continue
        comm=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        case "$comm" in
            *gst-launch*) continue ;; # our own producers (proxy/relay)
        esac
        echo "$pid"
    done
}

# v4l2loopback lets only one output fd set the format, so the proxy must be
# fully gone before the relay attaches (else S_FMT -> EBUSY). The swapping
# consumer already passed STREAMON, so the brief producer-less gap only
# stalls its stream, never errors it.
start_relay() {
    systemctl --user stop "$PROXY" 2>/dev/null
    sleep "$SWAP_WAIT"
    systemctl --user start "$RELAY"
}

stop_relay() {
    systemctl --user stop "$RELAY"
    systemctl --user start "$PROXY"
}

systemctl --user start "$PROXY"
last_open=$(date +%s)
while true; do
    if [ -n "$(consumers)" ]; then
        last_open=$(date +%s)
        if ! systemctl --user is-active --quiet "$RELAY"; then
            start_relay
        fi
    elif systemctl --user is-active --quiet "$RELAY"; then
        now=$(date +%s)
        if [ $((now - last_open)) -ge "$STOP_DELAY" ]; then
            stop_relay
        fi
    fi
    sleep "$POLL_SEC"
done
