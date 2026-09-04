local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd(noctCall .. "panel-toggle session"),     { description = "[Panels] Session panel (logout/lock)" })
hl.bind(mainMod .. " + Q",           hl.dsp.window.close(),                                   { description = "[System] Close window" })
hl.bind(mainMod .. " + SHIFT + Q",   hl.dsp.exec_cmd("hyprctl kill"),                         { description = "[System] Kill window" })
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }),              { description = "[Toggles] Toggle window floating" })
hl.bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }),                  { description = "[Toggles] Fullscreen (maximize)" })
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen(),                              { description = "[Toggles] Toggle fullscreen" })
hl.bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"),                            { description = "[Toggles] Toggle split (tiling)" })

-- Change focus
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left" }),   { description = "[Navigate] Focus window left" })
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }),  { description = "[Navigate] Focus window right" })
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up" }),     { description = "[Navigate] Focus window up" })
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down" }),   { description = "[Navigate] Focus window down" })
hl.bind("ALT + Tab",           hl.dsp.window.cycle_next(),             { description = "[Navigate] Cycle windows" })
hl.bind(mainMod .. " + Tab",   hl.dsp.exec_cmd(noctCall .. "window-switcher"), { description = "[Panels] Window switcher (noctalia)" })

-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + SHIFT + Up",                   hl.dsp.window.move({ direction = "u" }), { description = "[Navigate] Move window up" })
hl.bind(mainMod .. " + SHIFT + Right",                hl.dsp.window.move({ direction = "r" }), { description = "[Navigate] Move window right" })
hl.bind(mainMod .. " + SHIFT + Left",                 hl.dsp.window.move({ direction = "l" }), { description = "[Navigate] Move window left" })
hl.bind(mainMod .. " + SHIFT + Down",                 hl.dsp.window.move({ direction = "d" }), { description = "[Navigate] Move window down" })
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }), { description = "[Workspaces] Move window to workspace N" })
end
hl.bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "-1" }), { description = "[Navigate] Move window to previous monitor" })
hl.bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "+1" }), { description = "[Navigate] Move window to next monitor" })
hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.window.move({ workspace = "m+1" }), { description = "[Navigate] Move window to next workspace (monitor)" })
hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.window.move({ workspace = "m-1" }), { description = "[Navigate] Move window to previous workspace (monitor)" })
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "m-1" }), { description = "[Navigate] Move window to previous workspace" })
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }), { description = "[Navigate] Move window to next workspace" })
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. key, hl.dsp.window.move({ workspace = "m~" .. i }), { description = "[Workspaces] Move window to persistent workspace N" })
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { description = "[Navigate] Drag window (mouse)" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { description = "[Navigate] Resize window (mouse)" })

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
hl.bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { description = "[System] Zoom UI out", repeating = true })
hl.bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { description = "[System] Zoom UI in", repeating = true })

--# Zoom with keypad
hl.bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { description = "[System] Zoom UI out (keypad)", repeating = true })
hl.bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { description = "[System] Zoom UI in (keypad)", repeating = true })


------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return",     hl.dsp.exec_cmd(launchPrefix .. TERMINAL),                { description = "[Apps] Terminal (kitty)" })
hl.bind(mainMod .. " + ALT + Return",     hl.dsp.exec_cmd("~/.local/bin/launch-or-focus.sh " .. TMUX_CLASS .. " " .. launchPrefix .. TMUX_TERMINAL), { description = "[Apps] TMUX session (alacritty)" })
hl.bind(mainMod .. " + CONTROL + Return", hl.dsp.exec_cmd("~/.local/bin/launch-or-focus.sh " .. HERDR_CLASS .. " " .. launchPrefix .. HERDR_TERMINAL), { description = "[Apps] Herdr (launch or focus)" })
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER),            { description = "[Apps] File manager" })
hl.bind(mainMod .. " + SHIFT + E",  hl.dsp.exec_cmd(launchPrefix .. EDITOR),                  { description = "[Apps] Editor" })
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("~/.local/bin/launch-or-focus.sh " .. BROWSER_CLASS .. " " .. launchPrefix .. BROWSER), { description = "[Apps] Browser (launch or focus)" })
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"),  { description = "[Apps] btop (terminal)" })
hl.bind(mainMod .. " + B",          hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"),  { description = "[Apps] btop (terminal)" })
hl.bind(mainMod .. " + Z",          hl.dsp.exec_cmd(noctCall .. "settings-toggle"),           { description = "[Panels] Settings (noctalia)" })
hl.bind(mainMod .. " + X",          hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center"), { description = "[Panels] Control center" })
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"),     { description = "[Panels] Launcher" })
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher /emo"), { description = "[Panels] Emoji picker" })
hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd(noctCall .. "session lock"),              { description = "[System] Lock session" })
hl.bind(mainMod .. " + ALT + C",    hl.dsp.exec_cmd(noctCall .. "panel-toggle session"),      { description = "[Panels] Session panel" })

-------------------------
---- MICROSOFT 365 ----
-------------------------

hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.local/bin/launch-or-focus.sh " .. EVOLUTION_CLASS .. " " .. launchPrefix .. EVOLUTION), { description = "[Apps] Evolution mail (launch or focus)" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(launchPrefix .. CALENDAR),                { description = "[Apps] Calendar PWA" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e teams-tui-go"), { description = "[Apps] Teams (TUI)" })
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd(launchPrefix .. TEAMS),           { description = "[Apps] Teams (PWA)" })
hl.bind(mainMod .. " + CONTROL + T", hl.dsp.exec_cmd("~/.local/bin/toggle-dwt.sh"),  { description = "[Toggles] Toggle touchpad DWT (gaming)" })
hl.bind(mainMod .. " + CONTROL + W", hl.dsp.exec_cmd("~/.local/bin/toggle-wifi.sh"), { description = "[Toggles] Toggle wifi" })
hl.bind(mainMod .. " + CONTROL + B", hl.dsp.exec_cmd("~/.local/bin/toggle-bluetooth.sh"), { description = "[Toggles] Toggle bluetooth" })
hl.bind(mainMod .. " + CONTROL + H", hl.dsp.exec_cmd("~/.local/bin/connect-sony-headphones.sh"), { description = "[Toggles] Sony headphones (toggle)" })
hl.bind(mainMod .. " + CONTROL + P", hl.dsp.exec_cmd("~/.local/bin/toggle-lid-suspend.sh"), { description = "[Toggles] Toggle lid-close suspend" })
hl.bind(mainMod .. " + CONTROL + Y", hl.dsp.exec_cmd("~/.local/bin/toggle-tailscale.sh"), { description = "[Toggles] Toggle tailscale" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(launchPrefix .. TODO),                    { description = "[Apps] To Do PWA" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(launchPrefix .. OUTLOOK),         { description = "[Apps] Outlook PWA" })

------------------------
---- WEB APPS ----
------------------------

hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(launchPrefix .. YOUTUBE),                 { description = "[Apps] YouTube PWA" })
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(launchPrefix .. GITHUB),                  { description = "[Apps] GitHub" })
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("~/.local/bin/launch-or-focus.sh " .. OBSIDIAN_CLASS .. " " .. launchPrefix .. OBSIDIAN), { description = "[Apps] Obsidian (launch or focus)" })

--------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume-up"),   { description = "[Media] Volume up", locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume-down"), { description = "[Media] Volume down", locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume-mute"), { description = "[Media] Mute", locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { description = "[Media] Mic mute", locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media toggle"),   { description = "[Media] Media play/pause", locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { description = "[Media] Media play/pause", locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),     { description = "[Media] Media next", locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"), { description = "[Media] Media previous", locked = true })

-- Brightness (explicit MONITOR1 target: noctalia's "current" output resolution fails on this setup)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness-up " .. MONITOR1),   { description = "[Media] Brightness up (eDP-1)", locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness-down " .. MONITOR1), { description = "[Media] Brightness down (eDP-1)", locked = true, repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + P",     hl.dsp.exec_cmd("hyprpicker -a -n"),      { description = "[Capture] Color picker (hyprpicker)" })
hl.bind("Print",               hl.dsp.exec_cmd(noctCall .. "screenshot-region"),     { description = "[Capture] Screenshot region" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"), { description = "[Capture] Screenshot fullscreen" })

-- Theming and Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"), { description = "[Panels] Wallpaper panel" })

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(noctCall .. "panel-toggle clipboard"), { description = "[Panels] Clipboard panel" })

-- Notifications
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"), { description = "[Panels] Notifications panel" })

-- Keybind cheatsheet
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("~/.local/bin/cheatsheet.sh"), { description = "[System] Keybind cheatsheet" })

---------------------------
---- SNAPSHOTS (btrfs) ----
---------------------------

-- Create / list / manage snapper root snapshots (scripts in the scripts module)
hl.bind(mainMod .. " + CONTROL + S", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e ~/.local/bin/snapshot-create.sh"), { description = "[Snapshots] Create btrfs snapshot" })
hl.bind(mainMod .. " + CONTROL + L", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e ~/.local/bin/snapshot-list.sh"), { description = "[Snapshots] List btrfs snapshots" })
hl.bind(mainMod .. " + CONTROL + R", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e ~/.local/bin/snapshot-menu.sh"), { description = "[Snapshots] Snapshot menu (snapper)" })

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on workspace number
-- Absolute
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "[Workspaces] Focus workspace N" })
end
-- Relative
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }), { description = "[Workspaces] Focus persistent workspace N" })
end

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Right",       hl.dsp.focus({ workspace = "m+1" }),     { description = "[Workspaces] Next workspace (on monitor)" })
hl.bind(mainMod .. " + CONTROL + Left",        hl.dsp.focus({ workspace = "m-1" }),     { description = "[Workspaces] Previous workspace (on monitor)" })
hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.focus({ workspace = "emptym" }),  { description = "[Workspaces] Next empty workspace (on monitor)" })

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m-1" }), { description = "[Workspaces] Previous workspace (scroll)" })
hl.bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m+1" }), { description = "[Workspaces] Next workspace (scroll)" })
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m-1" }), { description = "[Workspaces] Previous workspace (scroll)" })
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }), { description = "[Workspaces] Next workspace (scroll)" })

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.workspace.toggle_special(), { description = "[System] Scratchpad (special workspace)" })

-- Gaming workspace (games are routed there by windowrules)
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.focus({ workspace = "name:gaming" }), { description = "[System] Gaming workspace" })

hl.bind(mainMod .. " + S",          hl.dsp.exec_cmd("~/.local/bin/launch-or-focus.sh " .. SPOTIFY_CLASS .. " " .. launchPrefix .. SPOTIFY), { description = "[Apps] Spotify (launch or focus)" })
hl.bind(mainMod .. " + SHIFT + S",  hl.dsp.exec_cmd("~/.local/bin/launch-or-focus.sh " .. SPOTIFY_TUI_CLASS .. " " .. launchPrefix .. SPOTIFY_TUI), { description = "[Apps] Spotify (TUI)" })


-- Manual internal-monitor toggle (F9) and reset (F10)
-- (Lid switch binds live in config/lid.lua, loaded after monitor rules)
hl.bind(mainMod .. "+ F9", hl.dsp.exec_cmd("~/.local/bin/toggle-edp.sh"), { description = "[System] Toggle internal display (eDP-1)" })

hl.bind(mainMod .. "+ F10", hl.dsp.exec_cmd('wlr-randr --output eDP-1 --on'), { description = "[System] Reset internal display (eDP-1 on)" })
