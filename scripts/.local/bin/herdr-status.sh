#!/bin/sh
# Compact herdr session summary for quick remote glances (e.g. over ssh
# from a phone). Read-only. Usage:
#   herdr-status.sh [--json]        full detail | collapsed summary
#
# Quick actions over ssh (headless herdr CLI, no HERDR_ENV needed):
#   herdr agent list                          all agents + states
#   herdr agent get <name>                    one agent
#   herdr agent read <name> --lines 60        recent transcript
#   herdr agent send-keys <name> ctrl+c       interrupt
#   herdr agent prompt <name> "..."           submit input
#   herdr pane read <pane-id> --lines 60      raw pane output
#   herdr pane run <pane-id> "cmd"            run a command in a pane

if [ "$1" = "--json" ]; then
    exec herdr pane list 2>/dev/null
fi

herdr pane list 2>/dev/null | jq -r '
  def short: . | sub("^OC \\| "; "") | .[0:72];
  .result.panes as $p |
  ($p | map(select(.agent_status == "working" or .agent_status == "blocked"))) as $hot |
  ($p | map(select(.agent_status == "idle"))) as $idle |
  ($p | map(select(.agent == null or .agent_status == "unknown"))) as $shells |
  "herdr · \($p|length) panes · \($p | map(.workspace_id) | unique | length) workspace(s)\n──────────────────────────────",
  (if ($hot|length) > 0 then
    "HOT" + ([$hot[] | "\n  \(.agent_status|ascii_upcase)  \(.agent // "?")  \(.pane_id)  \"\(.terminal_title_stripped|short)\""] | join(""))
   else "HOT   — none working or blocked" end),
  (if ($idle|length) > 0 then
    "IDLE  " + ([$idle[] | "\n  \(.agent // "?")  \(.pane_id)  \"\(.terminal_title_stripped|short)\""] | join(""))
   else "" end),
  "SHELL \($shells|length) plain terminal(s)"
' 2>/dev/null || echo "herdr server unreachable"
