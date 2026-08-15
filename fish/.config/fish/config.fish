if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

function fish_greeting
end

alias n="nvim"
alias f="fzf"
alias c="clear"
alias grep="grep --color=auto"
alias refresh="source ~/.config/fish/config.fish"
alias top="top -d 0.4"
alias who="who -u -H"
# Firefox path is OS-dependent; override in ~/.config/fish/conf.d/local.fish
# alias firefox="/snap/firefox/current/usr/lib/firefox/firefox"

alias l="ls"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias open="xdg-open"

alias t="tmux attach || tmux new"
alias tl="tmux ls"
alias td="tmux detach-client"

function ta
    tmux attach -t "$argv[1]"
end

function tn
    tmux new -s "$argv[1]"
end

function tk
    tmux kill-session -t "$argv[1]"
end

alias s="screen -ls"
alias ss="screen -S"
alias sr="screen -r"

alias ip-which="dig +short myip.opendns.com @resolver1.opendns.com"

alias pip="uv pip"
alias ipy="uv run --with ipython ipython"
alias task="uv run --with taskify task"

alias g="lazygit"
alias gs="git status"
alias gc="git commit"
alias gr="git checkout"
alias ga="git add"
alias gl="git lola"
alias newproject="cookiecutter gh:rendeirolab/_project_template"

function alert
    set -l last_status $status
    set -l icon terminal
    if test $last_status -ne 0
        set icon error
    end
    set -l last_command $history[1]
    set -l cleaned_command (string replace -r '\s*;\s*alert\s*$' '' $last_command)
    notify-send --urgency=low -i $icon $cleaned_command
end

function atcancelall
    for i in (atq | awk '{print $1}')
        atrm $i
    end
end

# Machine-specific aliases go in ~/.config/fish/conf.d/local.fish
# (SSH hosts, Bluetooth devices, printer names, etc.)

alias squeue="squeue -o '%.6i %9P %50j %.10u %.2t %.10M %.6D %R'"
alias sq="squeue | grep are"
alias wsq="watch 'squeue | grep are'"
alias bfg='java -jar ~/workspace/opt/bfg-1.14.0.jar'

alias printdoublesided='lpr -P imageFORCE-C5140-5150-UFR-II -o print-quality=5 -o sides=two-sided-long-edge -o ColorModel=AdobeRGB'
alias print="printdoublesided"

function printmin
    set -l name (basename $argv[1])
    pdfjam --landscape --nup 2x1 -o /tmp/$name $argv[1] 2>/dev/null
    if test -f /tmp/$name
        printdoublesided /tmp/$name
        rm /tmp/$name
    end
end

function toclipboard
    if test -n "$argv[1]"
        if command -q wl-copy; and test -n "$WAYLAND_DISPLAY"
            wl-copy < $argv[1]
        else
            xclip -selection clipboard -i $argv[1]
        end
    else
        if command -q wl-copy; and test -n "$WAYLAND_DISPLAY"
            wl-copy
        else
            xclip -selection clipboard -i
        end
    end
end

alias gpt='uvx --from gpt-command-line gpt --model gpt-4o'

if test -f ~/.config/fish/conf.d/local.fish
    source ~/.config/fish/conf.d/local.fish
end
