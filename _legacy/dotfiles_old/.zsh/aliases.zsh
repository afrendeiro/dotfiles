#!/usr/bin/env zsh

# Mostly from https://github.com/lvancrayelynghe/dotfiles

## Global aliases only works with ZSH
if [[ "$0" =~ 'zsh' ]]; then
    # Global directories aliases
    alias -g ..='..'
    alias -g ...='../..'
    alias -g ....='../../..'
    alias -g .....='../../../..'
    alias -g ......='../../../../..'
    alias -g .......='../../../../../..'

    # Global commands aliases
    alias -g X='| xargs'
    alias -g G='| grep'
    alias -g N='| grep -v'
    alias -g F='| fzf --ansi'
    # alias -g E='| grep-passthru'
    alias -g XS='| xargs subl'
    alias -g HR='| highlight red'
    alias -g HG='| highlight green'
    alias -g HB='| highlight blue'
    alias -g HM='| highlight magenta'
    alias -g HC='| highlight cyan'
    alias -g HY='| highlight yellow'
    alias -g C='| wc -l'
    alias -g S='| sort'
    alias -g H='| head'
    alias -g L="| less"
    alias -g T='| tail'
    alias -g P='| pygmentize -O style=monokai -f console256 -g'
else
    # Directories aliases
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
    alias ......='cd ../../../../..'
    alias .......='cd ../../../../../..'
fi

# Directories working
alias pwd=' pwd'
alias cd=' cd'
alias -- -=' cd -'
alias 1=' cd -'
alias 2=' cd -2'
alias 3=' cd -3'
alias 4=' cd -4'
alias 5=' cd -5'
alias 6=' cd -6'
alias 7=' cd -7'
alias 8=' cd -8'
alias 9=' cd -9'

alias l='ls -lh --group-directories-first'
alias ll='ls -lhA --group-directories-first'
alias llm='ls -lhAt --group-directories-first' ## "m" for sort by last modified date
alias llc='ls -lhAU --group-directories-first' ## "c" for sort by creation date
alias lls='ls -lhAS --group-directories-first' ## "s" for sort by size
alias lla='ll-archive' ## "a" for archive
# alias k='exa -abghHlS --group-directories-first'
# alias kk='exa -abghHlS --group-directories-first --git'
# alias kt='exa -hlTl --group-directories-first'
# alias ktt='exa -hlTlL=2 --group-directories-first'
# alias kttt='exa -hlTlL=3 --group-directories-first'

# 1 letter commands shortcuts
alias c=" clear && echo -ne '\033c' && printf '\e[3J'"
alias p=' dirs -v | head -10' ## most used dirs for current session
alias x=' exit'
alias d='desk'
alias h='history'
alias j='jobs'
alias t='tmux'
# alias v='open-with-vim'
# alias e='open-with-vim'
# alias s='open-with-sublime-text'
# alias a='open-with-atom'
# alias n='nano'

# Others commands shortcuts
alias dg='desk go'
alias zd='z --del'
alias k9='kill -9'
alias rd='rmdir'
alias md='mkdir -p'
alias mcd='mkdir-cd'
alias mkcd='mkdir-cd'
alias trm='trash-put'
alias rmf="rm -rf"
alias rmrf="rm -rf"
alias cpr="cp -r"
alias bak='backup-file'
alias psy='psysh'
alias run='make'
alias phpl='php -l'
alias tailf='tail -f'
alias less='less -r'
alias whence='type -a'
alias whereis='whereis'
alias grep='grep --color=auto'
alias vgrep='grep -v --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias mu='mutt'
alias mf='mutt -F'
alias zshrc='source ~/.zshrc' ## Reload config
alias refresh='source ~/.zshrc' ## Reload config
alias dotfiles='(cd ${DOTFILES_PATH} && git pull) ; (cd ${DOTFILES_PATH}/../private && git pull) ; source ~/.zshrc' ## Pull dotfiles from repositories and reload config
alias snippets="cat ${DOTFILES_PATH}/zsh/snippets.zsh | sed -r 's/^function //g' | sed -r 's/^# (.*)/\x1b[32m\x1b[1m# \1\x1b[0m/'"
alias top="top -d 0.4"

alias sudo='sudo ' ## Allow aliases to be sudo’ed
alias watch='watch ' ## Allow aliases to be watched


# Screen
alias s="screen -ls"
alias ss="screen -S"
alias sr="screen -r"

# CeMM cluster connection
alias hpc="ssh -X arendeiro@hpclogin"  # random node
alias hpc1="ssh -X arendeiro@n001.hpc.cemm.at"  # node 1
alias hpc2="ssh -X arendeiro@n002.hpc.cemm.at"  # node 2
alias hpcd="rdesktop-vrdp -f -u arendeiro -p - hpclogin.srv.cemm.at" # remote desktop
alias ngrok="ssh -X arendeiro@ngrok.com"

# slurm
alias sq="squeue | grep are"
alias wsq="watch 'squeue | grep are'"
alias sqc="squeue | grep are | wc -l"

# System stats
alias free='free -h'
alias ps='ps auxf'

# Search & find
alias sg='grep -rinw "." -e ' ## inside files
alias sa='ack -Hir' ## with ack
alias ss='sift -n' ## with sift
alias rg='rg -S' ## with ripgreprg
alias ff='find . -type f -iname ' ## insensitive filename
alias fr='find-and-replace' ## find and replace in current dir

# # Git
alias gs="git status"
alias gc="git commit"
alias gr="git checkout"
alias ga="git add"
alias gaa="git add -u"
alias gl='git log'
alias gcl='git clone --recursive'
# alias cdg=' cd "$(git rev-parse --show-toplevel)"' ## git root
# alias g='git'
# alias gcl='git clone --recursive'
# alias gcf='git config'
# alias gs='git status'
# alias gst='git status-short'
# alias ga='git add'
# alias gaa='git add -A'
# alias gmv='g mv'
# alias grm='g rm'
# alias gl='git log'
# alias gls='git log --stat' ## include which files were altered
# alias glp='git log -p' ## display the full diff of each commit
# alias gll='git pretty-log'
# alias gbl='git blame -b -w'
# alias gd='git diff'
# alias gdc='git diff --cached'
# alias gdw='git diff --word-diff'
# alias gdcw='git diff --cached --word-diff'
# alias gdt='git difftool'
# alias gw='git whatchanged'
# alias gg='git grep -n -C2 -E'
# alias gc='git commit -v'
# alias gc!='git commit -v --amend'
# alias gcu='git reset --soft HEAD~' ## undo commit
# alias gcm='git commit -m'
# alias gca='git commit -a'
# alias gcam='git commit -a -m'
# alias gb='git branch'
# alias gbm='git branch --merged'
# alias gbr='git branch -r'
# alias gbu='git remote update origin --prune' ## update remote list
# alias gm='git merge'
# alias gms='git merge --squash'
# alias gmm='git merge -m'
# alias gt='git tag'
# alias gco='git checkout'
# alias gcom='git checkout master'
# alias gcop='git checkout preprod'
# alias gcor='git checkout recette'
# alias gf='git fetch'
# alias gfo='git fetch origin'
# alias gp='git pull'
# alias gpull='git pull'
# alias gpush='git push'
# alias gpr='git pull --rebase'
# alias gsu='git set-upstream'
# alias gget='git get'
# alias gput='git put'
# alias ggp='git get-put'
# alias grb='git rebase'
# alias gss='git stash save'
# alias gsa='git stash apply'
# alias gsp='git stash pop'
# alias gsl='git stash list'
# alias ggc='git gc --aggressive'
# alias cgd='cdiff -s -w 0' ## columned & colored git diff
# alias cgs='columns-git-show' ## columned & colored git diff

# Docker
alias doi="docker images"
alias dov="docker volume"
alias doe="docker exec"
alias dok="docker kill"
alias dops="docker ps"
alias dorm="docker rm"
alias dormi="docker rmi"

# Docker compose
alias dc="docker-compose"
alias dce="docker-compose exec"
alias dcr="docker-compose run"
alias dcb="docker-compose build"
alias dcu="docker-compose up"
alias dcd="docker-compose down"
alias dcsa="docker-compose start"
alias dcso="docker-compose stop"
alias dcrm="docker-compose rm"
alias dsss="docker-sync-stack start"
alias dssc="docker-sync-stack clean"

# rsync
alias rsync-copy="rsync -av --progress -h --exclude-from=$HOME/.cvsignore"
alias rsync-move="rsync -av --progress -h --remove-source-files --exclude-from=$HOME/.cvsignore"
alias rsync-update="rsync -avu --progress -h --exclude-from=$HOME/.cvsignore"
alias rsync-synchronize="rsync -avu --delete --progress -h --exclude-from=$HOME/.cvsignore"

# Files permissions
alias 400='chmod 400 -R'
alias 600='chmod 600 -R'
alias 640='chmod 640 -R'
alias 644='chmod 644 -R'
alias 755='chmod 755 -R'
alias 775='chmod 775 -R'
alias 777='chmod 777 -R'
alias www="chown www-data:www-data * .* -R"
alias mx='chmod u+x'

# Dev helpers
# alias cs='php-cs-fixer --using-cache=false --rules=@Symfony,@PSR2 fix'

# SSH helpers
alias tunnel='ssh -f -N' ## Create a tunnel
alias tunnel-mysql='ssh -N -L 3307:localhost:3306' ## Create a MySQL tunnel
alias tunnel-socks='ssh -N -D 8080' ## SOCKS proxy
alias tunnel-list='ps aux | grep "ssh -f -N" | grep -v "grep"' ## List tunnels

# Datetime helpers
alias week='date +%V'
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# Network & ISP tests
alias myip='dig +short myip.opendns.com @resolver1.opendns.com'
alias myips="ifconfig -a | grep -o 'inet6\? \(ad\?dr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:|adr:)? ?/, \"\"); print }' | grep -v '127.0.0.1' | grep -v '::1'"
alias localip="ifconfig | grep -Eo 'inet (addr:|adr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"
alias speedtest="wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip"
alias ipstats="netstat -ntu | tail -n +3 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n"
alias ports="lsof -ni | grep LISTEN"
alias ns="nslookup"
alias he="sudo $EDITOR /etc/hosts"

# Curl & web helpers
alias dl='curl --continue-at - --location --progress-bar --remote-name --remote-time' ## download a file
alias weather='curl -A curl wttr.in'
alias wget-site='wget --mirror -p --convert-links -P'
alias header='curl-header'
alias purge='curl-purge'
for method in GET HEAD POST PUT DELETE PURGE TRACE OPTIONS; do
    alias "$method"="http '$method'"
done

# Online pastebins
alias sprunge="curl -F 'sprunge=<-' http://sprunge.us"
alias clbin="curl -F 'clbin=<-' https://clbin.com"

# Because Oo
alias tableflip="echo '(ノಠ益ಠ)ノ彡┻━┻'" ## see https://gist.github.com/endolith/157796
alias utf8test="wget -qO- http://8n1.org/utf8" ## test terminal UTF8 capabilities

# Global copy to clipboard
[[ "$0" =~ 'zsh' ]] && alias -g CC='| xclip -selection clipboard'

# Copy SSH public key to clipboard
alias pubkey="more ~/.ssh/id_rsa.pub | xclip | echo '=> Public key copied to pasteboard'"

# Copy working directory to clipboard
alias pwdc=' pwd | tr -d "\n" | xclip -selection clipboard'

# Open file
alias o='xdg-open 2>/dev/null'
alias open='xdg-open 2>/dev/null'

# Record x11
alias record="ffmpeg -f x11grab -s 1366x768 -an -r 16 -loglevel quiet -i :0.0 -b:v 5M -y" ## then pass a filename

# System commands
alias apt-installed="aptitude search '~i!~M'"
if [[ $UID != 0 || $EUID != 0 ]]; then
    alias halt='sudo shutdown -h now'
    alias reboot='sudo shutdown -r now'
    alias apt='sudo apt-get'
    alias agi='sudo apt-get install'
    alias agr='sudo apt-get remove'
    alias agu='sudo apt-get update'
    alias agg='sudo apt-get upgrade'
    alias ags='sudo apt-cache search'
    alias agall='sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade && sudo apt-get -y autoremove'
else
    alias halt='shutdown -h now'
    alias reboot='shutdown -r now'
    alias apt='apt-get'
    alias agi='apt-get install'
    alias agr='apt-get remove'
    alias agu='apt-get update'
    alias agg='apt-get upgrade'
    alias ags='apt-cache search'
    alias agall='apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -y autoremove'
fi
alias iotop='iotop -Poa' ## iotop with only processes using i/o + accumulated i/o
alias dmesg="dmesg -T|sed -e 's|\(^.*'`date +%Y`']\)\(.*\)|\x1b[0;34m\1\x1b[0m - \2|g'" ## dmesg with colored human-readable dates

# Disk usage
alias df='df -h'
alias du='du -h'
alias du0='du --max-depth=0'
alias du1='du --max-depth=1 | sort -k2' ## sort by name
alias du1s='du --max-depth=1 | sort -h' ## sort by size

# Datetime helpers
alias cal='cal -3'
