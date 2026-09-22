-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

-- The internal panel mirrors the physical lid switch (read once per config
-- apply): lid open -> custom modeline rule, lid closed -> output disabled.
-- Because every reload re-applies this, `hyprctl reload` (e.g. noctalia's
-- colors_changed hook) and boot with the lid closed can never resurrect the
-- panel. The lid binds apply the same rule at runtime; helpers live in
-- config/variables.lua.
hl.monitor(edp_rule(lid_is_closed()))

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
