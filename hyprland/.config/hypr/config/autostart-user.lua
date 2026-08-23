-- User autostart (tracked in dotfiles). Loaded from hyprland.lua.
-- CachyOS's config/autostart.lua stays untouched; add session start entries here.

hl.on("hyprland.start", function ()
    hl.exec_cmd(TERMINAL, { workspace = 4 })
end)
