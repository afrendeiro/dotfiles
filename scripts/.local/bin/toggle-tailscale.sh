#!/bin/sh
# Toggle tailscale on/off.
# CRITICAL: `up` must keep --accept-dns=false — MagicDNS breaks all DNS on
# this machine (NM writes /etc/resolv.conf directly; see
# notes/tailscale-ssh-remote.md). Never tailscale up without it.

if tailscale status >/dev/null 2>&1; then
    tailscale down
    notify-send -a tailscale "Tailscale" "down"
else
    tailscale up --accept-dns=false && notify-send -a tailscale "Tailscale" "up ($(tailscale ip -4))"
fi
