#! /bin/sh

# general
alias c="clear"
alias grep="grep --color=auto"
alias refresh="source ~/.bashrc"
alias top="top -d 0.4"
alias who="who -u -H"

# listing aliases
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
	alias l="ls --color"
	alias ll="ls -l -h --color"
	alias lla="ls -l -h -a --color"
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

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
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# iPython
alias ipy="ipython"

# git
alias gs="git status"
alias gc="git commit"
alias gr="git checkout"
alias ga="git add"
alias gl="git lola"

# Alert
# add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# CeMM stuff
# # ssh
alias ngrok="ssh -X arendeiro@ngrok.com"
alias hpc="ssh -X arendeiro@hpclogin"
alias hpc1="ssh -X arendeiro@n001.hpc.cemm.at"
alias hpc2="ssh -X arendeiro@n002.hpc.cemm.at"

# # remote desktop
alias hpcd="rdesktop -f -u arendeiro -p - hpclogin.srv.cemm.at"

# # slurm
alias sq="squeue | grep are"
alias wsq="watch 'squeue | grep are'"


# WCM stuff
# # ssh
FTP_TARGET="sftp://afr4001@pascal.med.cornell.edu/home/afr4001"
alias hpc_ftp="gio mount $FTP_TARGET; open $FTP_TARGET"
alias hpc="ssh -X afr4001@gateway.med.cornell.edu"
alias hpc1="ssh -X afr4001@pascal.med.cornell.edu"
alias hpc2="ssh -X afr4001@aristotle.med.cornell.edu"
alias hpc3="ssh -X afr4001@aphrodite.med.cornell.edu"
