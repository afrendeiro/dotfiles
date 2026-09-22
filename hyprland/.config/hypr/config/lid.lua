-- Lid switch binds. Loaded AFTER monitors.lua (switch binds can silently fail if
-- registered before hl.monitor rules).
--
-- The internal panel follows the lid state at runtime: closing removes eDP-1
-- from the layout (Hyprland moves its workspaces to the remaining monitor),
-- opening restores the custom modeline. monitors.lua derives the same state
-- from /proc on every config apply, so reloads and boot-with-lid-closed are
-- already correct. Helpers: set_internal_display()/edp_enabled() in
-- config/variables.lua.
--
-- Lid closed without an external display: suspend on battery while lid-close
-- sleep is enabled (~/.local/state/lid-suspend != "disabled", toggled by
-- toggle-lid-suspend.sh / SUPER+CTRL+P). On AC nothing happens, mirroring the
-- old logind profile. logind HandleLidSwitch=ignore — this binding owns lid
-- suspend. NEVER restart systemd-logind from a running session: it kills the
-- uwsm/Hyprland session (black screen).

local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local contents = file:read("*a")
    file:close()
    return contents
end

local function trimmed(contents)
    return (contents or ""):match("^%s*(.-)%s*$")
end

local function external_active()
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= "" and monitor.name ~= MONITOR1 then
            return true
        end
    end
    return false
end

-- Lid closed: eDP-1 off, then suspend if on battery without an external display.
hl.bind("switch:on:Lid Switch", function()
    if edp_enabled() then
        set_internal_display(true)
    end

    local state_dir = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
    local lid_suspend = trimmed(read_file(state_dir .. "/lid-suspend"))
    local ac_online = trimmed(read_file("/sys/class/power_supply/AC/online"))
    if not external_active() and lid_suspend ~= "disabled" and ac_online ~= "1" then
        hl.exec_cmd("systemctl suspend")
    end
end, { description = "Lid closed: eDP-1 off / suspend on battery", locked = true })

-- Lid opened: restore the internal panel.
hl.bind("switch:off:Lid Switch", function()
    if not edp_enabled() then
        set_internal_display(false)
    end
end, { description = "Lid opened: eDP-1 on", locked = true })
