#!/bin/sh
# SUPER+P — open a project from ~/work or ~/projects in a noctalia dmenu
# popup. Enter spawns a kitty terminal AND nautilus in the project dir.
# MRU (~/.local/state/open-project-mru, last 10) sorts to the top;
# remainder alphabetical.

MRU_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/open-project-mru"
mkdir -p "${MRU_FILE%/*}"

projects="$({
    sed -n '1,10p' "$MRU_FILE" 2>/dev/null
    for d in "$HOME"/work/*/ "$HOME"/projects/*/; do
        [ -d "$d" ] || continue
        echo "${d#$HOME/}" | sed 's:/*$::'
    done
} | awk '!seen[$0]++')"

[ -n "$projects" ] || exit 0

sel="$(printf '%s\n' "$projects" | noctalia dmenu -p "Open project")"
[ -n "$sel" ] || exit 0

path="$HOME/$sel"
[ -d "$path" ] || exit 1

sed -i "/^$sel$/d" "$MRU_FILE" 2>/dev/null
{ printf '%s\n' "$sel"; sed -n '1,9p' "$MRU_FILE" 2>/dev/null; } > "$MRU_FILE.tmp" && mv "$MRU_FILE.tmp" "$MRU_FILE"

uwsm app -- kitty -d "$path" > /dev/null 2>&1 &
uwsm app -- nautilus "$path" > /dev/null 2>&1 &
