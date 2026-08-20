#!/usr/bin/env sh
set -eu

# File picker popup body.
#
# Runs fzf over the current directory's file tree (directories first, hidden
# files skipped unless a dot prefix is typed). The preview pane shows a
# directory tree for directories and syntax-highlighted content for files.
# On selection the absolute path is copied to the clipboard and printed, then
# the popup closes (the command exits).
#
# Dependencies: fzf, tree, bat, wl-copy or xclip.
# Invoked from the manifest pane command with the popup cwd set to the
# focused pane's directory (see open.sh).

ROOT=$(pwd)

COPY_CMD=
if command -v wl-copy >/dev/null 2>&1; then
  COPY_CMD="wl-copy"
elif command -v xclip >/dev/null 2>&1; then
  COPY_CMD="xclip -selection clipboard"
fi

# Dirs first, then files; each line is relative to ROOT. The type marker
# survives sorting so awk can split dirs from files; fzf keeps input order
# with --no-sort, so dirs stay on top while typing a query.
find "$ROOT" \( -path '*/.*' \) -prune -o -printf '%y %p\n' 2>/dev/null \
  | sed "s|^\([df]\) $ROOT/|\1 |; s|^d \.$|d .|" \
  | sort -k1,1 -k2,2 \
  | awk '
      { t = $1; name = substr($0, 3)
        if (t == "d") dirs = dirs name "/\n"
        else          files = files name "\n" }
      END { printf "%s%s", dirs, files }' \
  | fzf \
      --multi \
      --no-sort \
      --header "enter: copy path · tab: multi · esc: cancel" \
      --preview-window='right:60%' \
      --preview "sh \"$HERDR_PLUGIN_ROOT/preview.sh\" '{1}'" \
  | while IFS= read -r sel; do
      case "$sel" in
        "") continue ;;
        /*) ;;
        .) sel="$ROOT" ;;
        *) sel="$ROOT/$sel" ;;
      esac
      if [ -n "$COPY_CMD" ]; then
        printf '%s\n' "$sel" | $COPY_CMD
      fi
      printf '%s\n' "$sel"
    done
