-- Lid switch binds. Loaded AFTER monitors.lua (switch binds can silently fail if
-- registered before hl.monitor rules).

-- After an output layout change, noctalia leaves the surviving bar surface at its
-- stale coordinates until something re-commits it. bar-reserve-toggle flips the
-- exclusive zone (which commits the layer surface); toggling twice restores state.
local bar_nudge = "sleep 1; noctalia msg bar-reserve-toggle; sleep 0.3; noctalia msg bar-reserve-toggle"

-- Lid closed: disable eDP-1 if an external monitor is present (dock/desk
-- use); otherwise suspend on battery while lid-close sleep is enabled
-- (~/.local/state/lid-suspend != "disabled", toggled by
-- toggle-lid-suspend.sh / SUPER+CTRL+P). logind HandleLidSwitch=ignore —
-- this binding owns lid suspend (on AC nothing happens, mirroring the old
-- logind profile). NEVER restart systemd-logind from a running session:
-- it kills the uwsm/Hyprland session (black screen).
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd([[bash -c '
if hyprctl monitors -j | jq -e "map(select(.name != \"eDP-1\" and .disabled == false)) | length > 0" >/dev/null 2>&1; then
    wlr-randr --output eDP-1 --off; ]] .. bar_nudge .. [[
elif [ "$(cat ~/.local/state/lid-suspend 2>/dev/null)" != "disabled" ] && [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" != "1" ]; then
    systemctl suspend
fi
']]), { locked = true })

-- Lid opened: re-enable the internal display (Hyprland re-applies the 60 Hz modeline rule)
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('wlr-randr --output eDP-1 --on; ' .. bar_nudge), { locked = true })
