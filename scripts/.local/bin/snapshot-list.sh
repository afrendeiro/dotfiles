#!/usr/bin/env bash
# List snapper root snapshots (pkexec).

if ! pkexec snapper -c root list; then
    echo "Listing failed or was cancelled." >&2
fi
read -rp "Press Enter to close."
