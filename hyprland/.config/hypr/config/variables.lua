-- Hyprland default apps

TERMINAL     = "kitty"
TMUX_TERMINAL  = 'alacritty --class tmux -e fish -l -c "tmux attach-session -t main || tmux new-session -s main"'
HERDR_TERMINAL = 'alacritty --class herdr -e herdr'
FILE_MANAGER = "nautilus"
BROWSER      = "brave-origin"
EDITOR       = "nvim"
SPOTIFY      = "spotify-launcher"
SPOTIFY_TUI  = 'kitty --class spotify-tui -e spotify_player'
MOE_TUI      = 'kitty --class moe-tui -e moe'
OBSIDIAN     = "obsidian"
EVOLUTION    = "org.gnome.Evolution.desktop"

-- Microsoft 365 PWAs
OUTLOOK  = "brave-origin --profile-directory=Default --app-id=eoficlgicibekocmfdomjbfnjmehnhcd"
CALENDAR = "brave-origin --profile-directory=Default --app='https://outlook.cloud.microsoft/calendar'"
TEAMS    = "brave-origin --profile-directory=Default --app-id=ompifgpmddkgmclendfeacglnodjjndh"
TODO     = "brave-origin --profile-directory=Default --app='https://outlook.office.com/host/0d5c91ee-5be2-4b79-81ed-23e6c4580427/ToDoId?bO=2'"

-- Web apps
YOUTUBE = "brave-origin --profile-directory=Default --app-id=agimnkijcaahngcdmfeangaknmldooml"
GITHUB  = "brave-origin --profile-directory=Default --app-id=mjoklplbddabcmpepnokjaffbmgbkkgg"

-- Window classes (app_id / WM_CLASS) for launch-or-focus binds
EVOLUTION_CLASS   = "org.gnome.Evolution"
SPOTIFY_CLASS     = "spotify"
SPOTIFY_TUI_CLASS = "spotify-tui"
MOE_TUI_CLASS     = "moe-tui"
TEAMS_TUI_CLASS   = "teams-tui"
OBSIDIAN_CLASS    = "obsidian"
BROWSER_CLASS     = "brave-origin"
TMUX_CLASS        = "tmux"
HERDR_CLASS       = "herdr"

-- Monitors
MONITOR1 = "eDP-1"
MONITOR2 = "DP-1"
MONITOR3 = ""

-- Prefer the external monitor when it's connected; otherwise use the internal
-- panel. hl.get_monitors() lists currently-active outputs, so this adapts to
-- "laptop only" vs "docked (external only)" automatically.
local function find_external()
    local ok, mons = pcall(hl.get_monitors)
    if not ok or mons == nil then
        return nil
    end
    for _, m in ipairs(mons) do
        if m.name ~= "" and m.name ~= MONITOR1 then
            return m.name
        end
    end
    return nil
end

PRIMARY_MONITOR = find_external() or MONITOR1

-- Internal panel (eDP-1): follows the physical lid switch. Lid open -> custom
-- modeline rule, lid closed -> output removed from the layout (Hyprland moves
-- its workspaces to the remaining monitor). config/monitors.lua applies the
-- rule at config-apply time; config/lid.lua and the F9/F10 binds call
-- set_internal_display() at runtime. No state file: every reload re-derives
-- from /proc, so a closed/sleeping panel can never be resurrected by a reload.
EDP_MODE = "modeline 193.25 1920 2056 2256 2592 1200 1203 1209 1245 -hsync +vsync"
LID_STATE_PATH = "/proc/acpi/button/lid/LID0/state"

function lid_is_closed()
    local file = io.open(LID_STATE_PATH, "r")
    if not file then
        return false
    end
    local state = file:read("*a") or ""
    file:close()
    return state:match("closed") ~= nil
end

function edp_enabled()
    return hl.get_monitor(MONITOR1) ~= nil
end

function edp_rule(disabled)
    if disabled then
        return { output = MONITOR1, disabled = true }
    end
    -- disabled must be set explicitly: hl.monitor() merges into the existing
    -- rule for this output, so omitting it would inherit a previous disable.
    return { output = MONITOR1, disabled = false, mode = EDP_MODE, position = "0x0", scale = "1.0" }
end

-- Apply the internal-panel state at runtime. hl.monitor() replaces the rule and
-- schedules a monitor refresh, so no config reload is needed. noctalia leaves
-- its bar surface at stale coordinates after an output layout change;
-- bar-reserve-toggle commits it, toggling twice restores the previous state.
function set_internal_display(disabled)
    hl.monitor(edp_rule(disabled))
    hl.exec_cmd("sleep 1; noctalia msg bar-reserve-toggle; sleep 0.3; noctalia msg bar-reserve-toggle")
    hl.exec_cmd("notify-send Display 'Internal monitor " .. (disabled and "off" or "on") .. "'")
end

-- Workspaces
NUM_WPM = 10 -- Number of workspaces per monitor (Max 10)
