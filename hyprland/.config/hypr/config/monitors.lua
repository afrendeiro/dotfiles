-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Example: output can be found with hyprctl monitors. Edit variables.lua for the monitor outputs instead of here directly
-- hl.monitor({
--     output    = "MONITOR1",
--     mode      = "1920x1080@60",
--     position  = "0x0",
--     scale     = "1",
-- })

hl.monitor({
    output    = MONITOR1,
    mode      = "modeline 193.25 1920 2056 2256 2592 1200 1203 1209 1245 -hsync +vsync",
    position  = "0x0",
    scale     = "1.0",
})
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
