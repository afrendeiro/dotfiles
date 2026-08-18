-- Lid switch binds. Loaded AFTER monitors.lua (switch binds can silently fail if
-- registered before hl.monitor rules).

-- After an output layout change, noctalia leaves the surviving bar surface at its
-- stale coordinates until something re-commits it. bar-reserve-toggle flips the
-- exclusive zone (which commits the layer surface); toggling twice restores state.
local bar_nudge = "sleep 1; noctalia msg bar-reserve-toggle; sleep 0.3; noctalia msg bar-reserve-toggle"

-- Lid closed: disable eDP-1 only if an external monitor is present
-- (battery + no external suspend is handled by logind, see /etc/systemd/logind.conf.d/)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd([[bash -c 'if hyprctl monitors -j | jq -e "map(select(.name != \"eDP-1\" and .disabled == false)) | length > 0" >/dev/null 2>&1; then wlr-randr --output eDP-1 --off; ]] .. bar_nudge .. [[; fi']]), { locked = true })

-- Lid opened: re-enable the internal display (Hyprland re-applies the 60 Hz modeline rule)
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('wlr-randr --output eDP-1 --on; ' .. bar_nudge), { locked = true })
