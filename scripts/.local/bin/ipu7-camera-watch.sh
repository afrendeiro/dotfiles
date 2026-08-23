#!/usr/bin/env bash
# Give browsers/apps the IPU7 camera without keeping the sensor (and its
# privacy LED) running while idle.
#
# ipu7-camera-proxy.service always writes a black 4K frame stream to
# /dev/video33, so the loopback always has a producer attached and consumers
# never hit the EIO/EBUSY cold-start race. While any app STREAMS the device,
# this watchdog swaps the proxy for ipu7-camera-relay.service (the real
# libcamera sensor); when the device has stayed unread for STOP_DELAY
# seconds it swaps back, so the sensor/LED only runs while the camera is
# actually used.
#
# Consumers are detected by scanning /proc fds (v4l2loopback >= 0.15 emits
# no open/close uevents) and are filtered by open flags: enumeration and
# monitoring opens are O_RDONLY (Chromium's capture service keeps /dev/video*
# fds open permanently, the portal/pipewire probes are brief); real streaming
# opens are O_RDWR/O_WRONLY. Only those count, so probes can never trigger a
# swap or keep the relay running.
#
# The loopback uses exclusive_caps=1: Chromium's V4L2 factory skips devices
# advertising both CAPTURE and OUTPUT caps (crbug.com/139356), and with
# exclusive_caps the device advertises CAPTURE while a producer is attached.
# See notes/camera-ipu7.md.
set -u

DEV=/dev/video33
RELAY=ipu7-camera-relay.service
PROXY=ipu7-camera-proxy.service
# Only swap the proxy for the real relay after a streaming consumer has been
# attached for this long (probes are filtered out by open flags already; the
# hold is a safety margin).
CONSUMER_HOLD=1
STOP_DELAY=15
POLL_SEC=0.5
SWAP_WAIT=1

# Streaming consumers: pids holding $DEV with an O_RDWR or O_WRONLY fd
# (flags bit 1 or 2), excluding our own producers (gst-launch).
consumers() {
    local pid fd target flags
    for pid in $(lsof -t "$DEV" 2>/dev/null); do
        [ -d "/proc/$pid" ] || continue
        comm=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        case "$comm" in
            *gst-launch*) continue ;; # our own producers (proxy/relay)
        esac
        for fd in /proc/$pid/fd/*; do
            target=$(readlink "$fd" 2>/dev/null) || continue
            [ "$target" = "$DEV" ] || continue
            flags=$(awk '/^flags:/{print $2}' "/proc/$pid/fdinfo/${fd##*/}" 2>/dev/null)
            [ -n "$flags" ] || continue
            if [ $((flags & 3)) -ne 0 ]; then
                echo "$pid"
                return 0
            fi
        done
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
first_seen=0
while true; do
    if [ -n "$(consumers)" ]; then
        last_open=$(date +%s)
        if [ "$first_seen" -eq 0 ]; then
            first_seen=$(date +%s)
        fi
        if systemctl --user is-active --quiet "$RELAY"; then
            first_seen=0
        elif [ $((last_open - first_seen)) -ge "$CONSUMER_HOLD" ]; then
            start_relay
            first_seen=0
        fi
    else
        first_seen=0
        if systemctl --user is-active --quiet "$RELAY"; then
            now=$(date +%s)
            if [ $((now - last_open)) -ge "$STOP_DELAY" ]; then
                stop_relay
            fi
        elif ! systemctl --user is-active --quiet "$PROXY"; then
            # Relay gone and no consumers: make sure the proxy holds the
            # device (recovery from relay crash-loops / manual stops).
            systemctl --user start "$PROXY"
        fi
    fi
    sleep "$POLL_SEC"
done
