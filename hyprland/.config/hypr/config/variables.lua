-- Hyprland default apps

TERMINAL     = "kitty"
TMUX_TERMINAL  = 'alacritty -e fish -l -c "tmux attach-session -t main || tmux new-session -s main"'
HERDR_TERMINAL = 'alacritty -e herdr'
FILE_MANAGER = "nautilus"
BROWSER      = "brave-origin"
EDITOR       = "gnome-text-editor --new-window"

-- Microsoft 365 PWAs
OUTLOOK  = "brave-origin --profile-directory=Default --app-id=eoficlgicibekocmfdomjbfnjmehnhcd"
CALENDAR = "brave-origin --profile-directory=Default --app='https://outlook.cloud.microsoft/calendar'"
TEAMS    = "brave-origin --profile-directory=Default --app-id=ompifgpmddkgmclendfeacglnodjjndh"
TODO     = "brave-origin --profile-directory=Default --app='https://outlook.office.com/host/0d5c91ee-5be2-4b79-81ed-23e6c4580427/ToDoId?bO=2'"

-- Monitors
MONITOR1 = "eDP-1"
MONITOR2 = "DP-1"
MONITOR3 = ""
PRIMARY_MONITOR = MONITOR1

-- Workspaces
NUM_WPM = 6 -- Number of workspaces per monitor (Max 10)
