#!/usr/bin/env bash
set -euo pipefail

# Firmware update helper via fwupd (Dell XPS 14).
# Usage:
#   update-firmware.sh          refresh metadata and apply available updates
#   update-firmware.sh --check  refresh metadata and list updates only
#   update-firmware.sh -h       show this help
#
# System Firmware and NVMe updates require AC power; the script aborts on
# battery. Elevates through pkexec (GUI polkit prompt) when not root, since
# sudo fails in non-interactive shells.

AC_ONLINE=/sys/class/power_supply/AC/online

usage() {
    sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

is_root() {
    [ "$(id -u)" -eq 0 ]
}

run() {
    if is_root; then
        "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        pkexec "$@"
    else
        sudo "$@"
    fi
}

require_ac() {
    if [ ! -e "$AC_ONLINE" ]; then
        echo "WARNING: cannot determine power state, assuming AC power" >&2
        return 0
    fi
    if [ "$(cat "$AC_ONLINE")" != "1" ]; then
        echo "ERROR: firmware updates require AC power — plug in the charger" >&2
        exit 1
    fi
}

refresh() {
    echo "=== Refreshing firmware metadata ==="
    # fwupdmgr's summary bullets count device *capabilities* and metadata
    # matches, not pending updates: "X devices are updatable" = how many could
    # receive firmware at all, "Y ... supported in the enabled remotes" = how
    # many have any published firmware entry (may already be current). Relabel
    # them so they aren't mistaken for available updates; get-updates below is
    # the authoritative check.
    run fwupdmgr refresh --force 2>&1 | sed -E \
        -e 's/^ • ([0-9]+) devices? (is|are) updatable$/* \1 updatable-capable (capability count, not pending updates)/' \
        -e 's/^ • ([0-9]+) devices? (is|are) supported in the enabled remotes \(an update has been published\)$/* \1 matched published firmware metadata (may already be current; get-updates is authoritative)/' \
        -e 's/^No devices are updatable$/No devices are updatable-capable/'
}

check() {
    echo "=== Checking for firmware updates (authoritative result) ==="
    run fwupdmgr get-updates || true
}

apply() {
    echo "=== Applying firmware updates ==="
    run fwupdmgr update -y
    echo
    echo "Firmware updates applied — REBOOT to finish installing."
}

case "${1:-}" in
    -h|--help) usage ;;
    --check)
        refresh
        check
        ;;
    *)
        require_ac
        refresh
        if check 2>&1 | grep -qiE "no updates available"; then
            echo "No firmware updates available."
        else
            echo
            read -r -p "Apply the updates now? [y/N] " ans
            case "${ans:-n}" in
                y|Y|yes|Yes) apply ;;
                *) echo "Skipping. Re-run when ready." ;;
            esac
        fi
        ;;
esac
