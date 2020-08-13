#! /bin/sh

# general
alias c="clear"
alias grep="grep --color=auto"
alias refresh="source ~/.bashrc"
alias top="top -d 0.4"
alias who="who -u -H"

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
alias open="xdg-open 2>/dev/null"

# screen
alias s="screen -ls"
alias ss="screen -S"
alias sr="screen -r"

# IP
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# iPython
alias ipy="ipython"

# git
alias gs="git status"
alias gc="git commit"
alias gr="git checkout"
alias ga="git add"

# ssh
alias ngrok="ssh -X arendeiro@ngrok.com"
alias hpc="ssh -X arendeiro@hpclogin"
alias hpc1="ssh -X arendeiro@n001.hpc.cemm.at"
alias hpc2="ssh -X arendeiro@n002.hpc.cemm.at"

# remote desktop
alias hpcd="rdesktop -f -u arendeiro -p - hpclogin.srv.cemm.at"

# slurm
alias sq="squeue | grep are"
alias wsq="watch 'squeue | grep are'"

# Looper
alias lor="looper run metadata/project_config.yaml > looper_run.log"
alias lord="looper run -d metadata/project_config.yaml > looper_run.dry.log"
alias loc="looper check metadata/project_config.yaml > looper_check.log"
alias los="looper summarize metadata/project_config.yaml > looper_summarize.log"
