#!/usr/bin/env sh
set -eu

# fzf preview pane body. Invoked as `sh "$HERDR_PLUGIN_ROOT/preview.sh" '{1}'`
# so it runs under sh regardless of the user's $SHELL (fish would misparse
# POSIX syntax inline).

sel=$1

if [ -d "$sel" ]; then
  tree -C --dirsfirst -L 2 "$sel" 2>/dev/null || ls -la "$sel"
else
  bat --color=always --style=numbers,header "$sel" 2>/dev/null | head -200
fi
