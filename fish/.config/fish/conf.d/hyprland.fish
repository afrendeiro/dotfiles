if command -q hyprctl
    alias mon='hyprctl monitors -j | jq ".[].name"'
end
