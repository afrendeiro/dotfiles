-- User autostart (tracked in dotfiles). Loaded from hyprland.lua.
-- CachyOS's config/autostart.lua stays untouched; add session start entries here.

hl.on("hyprland.start", function ()
    hl.exec_cmd(TERMINAL, { workspace = 4 })
end)

-- Keyring / passphrase prompts: float, centered, sticky (pin) so they can
-- never be stranded on a hidden workspace again.
hl.window_rule({ match = { class = "gcr-prompter" }, float = true, center = true, pin = true })
hl.window_rule({ match = { class = "^(pinentry.*)$" }, float = true, center = true, pin = true })

-- Fallback background (visible before noctalia's wallpaper surface maps, e.g.
-- on monitor on/off): plain black instead of the default anime/logo wallpaper.
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = "rgb(000000)",
    },
})

-- Touchpad: allow camera-look while keys are held (DWT suppresses the pad while typing/WASD)
hl.config({ input = { touchpad = { disable_while_typing = false } } })
