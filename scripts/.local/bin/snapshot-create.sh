#!/usr/bin/env bash
# Create a snapper root snapshot, prompting for a description (pkexec).

set -u

printf 'Description for the snapshot (empty = "manual"): '
read -r desc
[ -n "${desc}" ] || desc="manual"
desc="${desc} ($(date '+%Y-%m-%d %H:%M:%S'))"

if pkexec snapper -c root create -d "${desc}"; then
    notify-send -a snapper "Snapshot created" "${desc}" 2>/dev/null || true
    echo
    echo "Snapshot created: ${desc}"
else
    echo
    echo "Snapshot creation failed or was cancelled - see output above." >&2
fi
read -rp "Press Enter to close."
