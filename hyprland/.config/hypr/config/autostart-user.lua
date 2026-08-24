-- User autostart (tracked in dotfiles). Loaded from hyprland.lua.
-- CachyOS's config/autostart.lua stays untouched; add session start entries here.

hl.on("hyprland.start", function ()
    hl.exec_cmd(TERMINAL, { workspace = 4 })
end)

-- Keyring / passphrase prompts: float, centered, sticky (pin) so they can
-- never be stranded on a hidden workspace again.
hl.window_rule({ match = { class = "gcr-prompter" }, float = true, center = true, pin = true })
hl.window_rule({ match = { class = "^(pinentry.*)$" }, float = true, center = true, pin = true })
