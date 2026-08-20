#!/usr/bin/env sh
set -eu

# Open the file picker popup over the currently focused pane's working
# directory. Bound to prefix+f via [[keys.command]] type = "plugin_action".
#
# Popup pane commands run with the popup cwd, not the plugin root, so the
# manifest uses "sh -c $HERDR_PLUGIN_ROOT/pick.sh" to resolve the script.
# Pass --cwd explicitly so pick.sh starts where the focused pane is.

HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
CWD=$(printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" | sed -n 's/.*"focused_pane_cwd":"\([^"]*\)".*/\1/p')
CWD=${CWD:-$HOME}

"$HERDR_BIN" plugin pane open \
  --plugin file-picker \
  --entrypoint pick \
  --placement popup \
  --cwd "$CWD"
