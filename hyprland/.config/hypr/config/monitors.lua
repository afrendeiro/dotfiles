-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

-- The internal panel state is owned by ~/.local/bin/toggle-edp.sh (SUPER+F9/F10
-- and the lid binds), persisted in ${XDG_STATE_HOME:-~/.local/state}/edp-state.
-- Hyprland re-applies monitor rules on every reload, so the rule must mirror the
-- state or the panel would come back on (e.g. noctalia's colors_changed reload).
local function internal_display_enabled()
    local dir = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
    local file = io.open(dir .. "/edp-state", "r")
    if not file then
        return true
    end
    local state = file:read("*l")
    file:close()
    return state ~= "off"
end

if internal_display_enabled() then
    hl.monitor({
        output    = MONITOR1,
        mode      = "modeline 193.25 1920 2056 2256 2592 1200 1203 1209 1245 -hsync +vsync",
        position  = "0x0",
        scale     = "1.0",
    })
else
    hl.monitor({
        output    = MONITOR1,
        disabled  = true,
    })
end
hl.monitor({
    output    = MONITOR2,
    mode      = "3840x2160@60",
    position  = "auto-right",
    scale     = "1.0",
})
hl.monitor({
    output    = "",
    mode      = "preferred",
    position  = "auto",
    scale     = "1.0",
})
