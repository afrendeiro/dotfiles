#!/usr/bin/env bash
# (Re)create the CeMM printer queues.
#
# CeMM's imageFORCE printers (2026 upgrade) no longer expose IPP -- port 631 is
# closed and the devices are not advertised over mDNS/Bonjour, so `-m everywhere`
# no longer works. They still accept plain PostScript over the raw socket port
# (9100) without authentication, so the queues use socket:// URIs with a
# PostScript PPD (CUPS converts PDF -> PS on the fly); no proprietary Canon
# driver is needed.
#
# Usage: setup-printers.sh [-n CeMM_level_2]
#
# Known devices (verified 2026-09-21, old reservations still in place):
#   level 2 = 193.171.185.37    level 4 = 193.171.185.39
#   level 6 = 193.171.185.38    level 7 = 193.171.185.41
#   level 3 (193.171.185.212) and level 5 (193.171.185.40) no longer respond.

set -euo pipefail

PPD="foomatic:Canon-iR-ADV_C5235_5240-Postscript.ppd"

declare -A PRINTERS=(
    [CeMM_level_2]=193.171.185.37
    # [CeMM_level_4]=193.171.185.39
    # [CeMM_level_6]=193.171.185.38
    # [CeMM_level_7]=193.171.185.41
)

only=""
if [ "${1:-}" = "-n" ]; then
    only="${2:?missing printer name}"
fi

names=("${!PRINTERS[@]}")
if [ -n "$only" ]; then
    names=("$only")
fi

for name in "${names[@]}"; do
    ip="${PRINTERS[$name]:-}"
    if [ -z "$ip" ]; then
        echo "setup-printers: unknown printer '$name'" >&2
        exit 1
    fi
    echo "== $name -> socket://$ip:9100"
    lpadmin -p "$name" -E -v "socket://$ip:9100" -m "$PPD" \
        -D "CeMM printer ($name, PostScript via socket)" -L "CeMM" \
        -o PageSize=A4 -o sides=two-sided-long-edge -o ColorModel=Auto
done

# The level-2 queue is the everyday default.
if lpstat -p CeMM_level_2 >/dev/null 2>&1; then
    lpadmin -d CeMM_level_2
fi

lpstat -v
