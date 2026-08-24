-- Hyprland default apps

TERMINAL     = "kitty"
TMUX_TERMINAL  = 'alacritty --class tmux -e fish -l -c "tmux attach-session -t main || tmux new-session -s main"'
HERDR_TERMINAL = 'alacritty --class herdr -e herdr'
FILE_MANAGER = "nautilus"
BROWSER      = "brave-origin"
EDITOR       = "nvim"
SPOTIFY      = 'kitty --class spotify-tui -e spotify_player'
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
SPOTIFY_CLASS     = "spotify-tui"
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

-- Workspaces
NUM_WPM = 10 -- Number of workspaces per monitor (Max 10)
