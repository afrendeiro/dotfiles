#!/usr/bin/env bash
# fzf menu over snapper root snapshots: diff against current, or restore the
# snapshot's boot kernel/initramfs files from the boot partition (pkexec).

set -u

rows="$(pkexec snapper -c root list --columns number,date,description \
    | awk -F'│' '$1 ~ /^[[:space:]]*[0-9]+[[:space:]]*$/ {
          gsub(/[[:space:]]+/, "", $1)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3)
          print $1 " | " $2 " | " $3
      }' | sort -t'|' -k1 -rn)"

if [ -z "${rows}" ]; then
    echo "No snapshots found, or listing was cancelled." >&2
    read -rp "Press Enter to close."
    exit 1
fi

sel="$(printf '%s\n' "${rows}" | fzf --prompt='Snapshot: ' --no-sort)"
if [ -z "${sel}" ]; then
    exit 0
fi
id="$(printf '%s' "${sel}" | cut -d'|' -f1 | tr -d ' ')"

action="$(printf 'diff against current\nrestore boot files\n' \
    | fzf --prompt="Snapshot ${id}: " --no-sort)"
case "${action}" in
    diff*)
        if ! pkexec snapper -c root diff "${id}"; then
            echo "Diff failed or was cancelled." >&2
        fi
        ;;
    restore*)
        read -rp "Restore kernel/initramfs files of snapshot ${id} into /boot? [y/N] " ans
        if [ "${ans}" = y ] || [ "${ans}" = Y ]; then
            if ! pkexec limine-snapper-restore --kernels "${id}"; then
                echo "Restore failed or was cancelled." >&2
            fi
        fi
        ;;
esac
read -rp "Press Enter to close."
