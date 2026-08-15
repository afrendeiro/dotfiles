-- Hyprland default apps

TERMINAL     = "kitty"
TMUX_TERMINAL  = 'alacritty -e fish -l -c "tmux attach-session -t main || tmux new-session -s main"'
HERDR_TERMINAL = 'alacritty -e herdr'
FILE_MANAGER = "nautilus"
BROWSER      = "brave-origin"
EDITOR       = "nvim"

-- Microsoft 365 PWAs
OUTLOOK  = "brave-origin --profile-directory=Default --app-id=eoficlgicibekocmfdomjbfnjmehnhcd"
CALENDAR = "brave-origin --profile-directory=Default --app='https://outlook.cloud.microsoft/calendar'"
TEAMS    = "brave-origin --profile-directory=Default --app-id=ompifgpmddkgmclendfeacglnodjjndh"
TODO     = "brave-origin --profile-directory=Default --app='https://outlook.office.com/host/0d5c91ee-5be2-4b79-81ed-23e6c4580427/ToDoId?bO=2'"

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
