#! /bin/sh

alias f="fzf"

# general
alias c="clear"
alias grep="grep --color=auto"
alias refresh="source ~/.bashrc"
alias top="top -d 0.4"
alias who="who -u -H"
alias firefox="/snap/firefox/current/usr/lib/firefox/firefox"

# listing aliases
alias l="ls --color"
alias ll="ls -l -h --color"
alias lla="ls -l -h -a --color"

# movement aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# open
alias open="xdg-open"

# screen
alias s="screen -ls"
alias ss="screen -S"
alias sr="screen -r"

# IP
alias ip-which="dig +short myip.opendns.com @resolver1.opendns.com"

# iPython
# alias python="python"
alias pip="uv pip"
alias ipy="uv run --with ipython ipython"
alias task="uv run --with taskify task"

# git
alias g="lazygit"
alias gs="git status"
alias gc="git commit"
alias gr="git checkout"
alias ga="git add"
alias gl="git lola"
alias newproject="uvx cookiecutter https://github.com/rendeirolab/_project_template"

# Alert
# add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Bluetooth
alias bconnect="echo -e 'connect AC:12:2F:DA:E3:5A \nquit' | bluetoothctl"
alias dconnect="echo -e 'disconnect AC:12:2F:DA:E3:5A \nquit' | bluetoothctl"

# Snakemake
# alias snakemake="docker run --rm -w /mount/ --name snakemake -v `pwd`:/mount/ snakemake/snakemake:v7.8.3 snakemake"

# at
alias atcancelall="for i in `atq | awk '{print $1}'`;do atrm $i;done"

# CeMM stuff
# # ssh
alias hpc="ssh -X arendeiro@login"
alias hpc1="ssh -X arendeiro@10.110.81.1"
alias hpc2="ssh -X arendeiro@10.110.81.2"
alias hilde="ssh -X arendeiro@hilde.int.cemm.at"
alias hilde2="ssh -X arendeiro@193.171.185.239"
# # smb

# # VMs
alias cytomine="ssh -X arendeiro@cytomine.int.cemm.at"

# # slurm
alias squeue="squeue -o '%.6i %9P %50j %.10u %.2t %.10M %.6D %R'"
alias sq="squeue | grep are"
alias wsq="watch 'squeue | grep are'"
alias bfg='java -jar bfg.jar'
alias bfg='java -jar ~/workspace/opt/bfg-1.14.0.jar'

# Misc
alias newproject="cookiecutter gh:rendeirolab/_project_template"
alias printdoublesided='lpr -P imageFORCE-C5140-5150-UFR-II -o print-quality=5 -o sides=two-sided-long-edge -o ColorModel=AdobeRGB'
alias print="printdoublesided"

printmin(){  # pass a file as argument
    NAME=`basename $1`
    # pdfjam --landscape --nup 2x1 -o /dev/stdout $1 | lpr -P Canon_iR_ADV_C5535_5540_a8_d6_b6@CanonA8D6B6.local -o sides=two-sided-long-edge
    pdfjam --landscape --nup 2x1 -o /tmp/${NAME} $1 2> /dev/null
    if [ -f /tmp/${NAME} ]; then
        print /tmp/${NAME}
        rm /tmp/${NAME}
    fi
}

# Copy content of file to clipboard
alias toclipboard='xclip -selection clipboard -i < '

# GPT
alias gpt='uvx --from gpt-command-line gpt --model gpt-4o'

