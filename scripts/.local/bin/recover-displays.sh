#!/usr/bin/env bash
# Recover external displays after the aquamarine 0.15.0 disconnect regression:
# an external monitor that stays dead after unplugging/replugging the dock.
# See notes/dock-display-replug.md.
#
# A VT switch makes fbcon do a full modeset, which releases the stale CRTC that
# keeps the Intel Type-C port out of DP-alt mode. chvt needs CAP_SYS_TTY_CONFIG,
# so elevate with pkexec (one GUI polkit prompt).

session="${XDG_SESSION_ID:-}"
current="$(loginctl show-session "$session" -p VTNr --value 2>/dev/null)"
case "$current" in
    ''|*[!0-9]*) current=1 ;;
esac
other=2
[ "$current" -eq 2 ] && other=3

notify-send -a hyprland "Displays" "Recovering external displays (VT switch)"
pkexec sh -c "chvt $other; sleep 1; chvt $current"
