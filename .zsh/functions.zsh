#!/usr/bin/env zsh

# List content of archive but don't extract
function ll-archive() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2|*.tbz2|*.tbz)  tar -jtf "$1"     ;;
            *.tar.gz)                tar -ztf "$1"     ;;
            *.tar|*.tgz|*.tar.xz)    tar -tf  "$1"     ;;
            *.gz)                    gzip -l  "$1"     ;;
            *.rar)                   rar vb   "$1"     ;;
            *.zip)                   unzip -l "$1"     ;;
            *.7z)                    7z l     "$1"     ;;
            *.lzo)                   lzop -l  "$1"     ;;
            *.xz|*.txz|*.lzma|*.tlz) xz -l    "$1"     ;;
        esac
    else
        echo "Sorry, '$1' is not a valid archive."
        echo "Valid archive types are:"
        echo "tar.bz2, tar.gz, tar.xz, tar, gz,"
        echo "tbz2, tbz, tgz, lzo, rar"
        echo "zip, 7z, xz and lzma"
    fi
}

# Extract an archive
function extract() {
    if [ -z "$2" ]; then 2="."; fi
    if [ -f "$1" ] ; then
        case "$1" in
            *.tar.bz2|*.tbz2|*.tbz)       mkdir -v "$2" 2>/dev/null ; tar xvjf "$1" -C "$2"  ;;
            *.tar.gz|*.tgz)               mkdir -v "$2" 2>/dev/null ; tar xvzf "$1" -C "$2"  ;;
            *.tar.xz)                     mkdir -v "$2" 2>/dev/null ; tar xvJf "$1"          ;;
            *.tar)                        mkdir -v "$2" 2>/dev/null ; tar xvf  "$1" -C "$2"  ;;
            *.rar)                        mkdir -v "$2" 2>/dev/null ; unrar x  "$1"          ;;
            *.zip)                        mkdir -v "$2" 2>/dev/null ; unzip    "$1" -d "$2"  ;;
            *.7z)                         mkdir -v "$2" 2>/dev/null ; 7z x     "$1" -o"$2"   ;;
            *.lzo)                        mkdir -v "$2" 2>/dev/null ; lzop -d  "$1" -p "$2"  ;;
            *.gz)                         gunzip "$1"                                        ;;
            *.bz2)                        bunzip2 "$1"                                       ;;
            *.Z)                          uncompress "$1"                                    ;;
            *.xz|*.txz|*.lzma|*.tlz)      xz -d "$1"                                         ;;
            *)
        esac
    else
        echo "Sorry, '$1' could not be decompressed."
        echo "Usage: extract <archive> <destination>"
        echo "Example: extract PKGBUILD.tar.bz2 ."
        echo "Valid archive types are:"
        echo "tar.bz2, tar.gz, tar.xz, tar, bz2,"
        echo "gz, tbz2, tbz, tgz, lzo,"
        echo "rar, zip, 7z, xz and lzma"
    fi
}

# compress a file or folder
function compress() {
        case "$1" in
        tar.bz2|.tar.bz2) tar cvjf "${2%%/}.tar.bz2" "${2%%/}/" ;;
        tbz2|.tbz2)       tar cvjf "${2%%/}.tbz2" "${2%%/}/"    ;;
        tbz|.tbz)         tar cvjf "${2%%/}.tbz" "${2%%/}/"     ;;
        tar.xz)           tar cvJf "${2%%/}.tar.xz" "${2%%/}/"  ;;
        tar.gz|.tar.gz)   tar cvzf "${2%%/}.tar.gz" "${2%%/}/"  ;;
        tgz|.tgz)         tar cvjf "${2%%/}.tgz" "${2%%/}/"     ;;
        tar|.tar)         tar cvf  "${2%%/}.tar" "${2%%/}/"     ;;
        rar|.rar)         rar a "${2}.rar" "$2"                 ;;
        zip|.zip)         zip -r -9 "${2}.zip" "$2"             ;;
        7z|.7z)           7z a "${2}.7z" "$2"                   ;;
        lzo|.lzo)         lzop -v "$2"                          ;;
        gz|.gz)           gzip -r -v "$2"                       ;;
        bz2|.bz2)         bzip2 -v "$2"                         ;;
        xz|.xz)           xz -v "$2"                            ;;
        lzma|.lzma)       lzma -v "$2"                          ;;
        *)                echo "Compress a file or directory."
        echo "Usage:   compress <archive type> <filename>"
        echo "Example: ac tar.bz2 PKGBUILD"
        echo "Please specify archive type and source."
        echo "Valid archive types are:"
        echo "tar.bz2, tar.gz, tar.gz, tar, bz2, gz, tbz2, tbz,"
        echo "tgz, lzo, rar, zip, 7z, xz and lzma." ;;
    esac
}

# Show aliases and functions cheat-sheet
function cheat-sheet() {
    cat "${DOTFILES_PATH}/zsh/aliases.zsh" |
        perl -p0e 's/\nelse\n.*?\nfi\n/\n/sg' |
        perl -p0e 's/\nfor .*?done\n//sg' |
        grep -v "^if " |
        grep -v "^elif " |
        grep -v "^fi$" |
        grep -v "^    if " |
        grep -v "^    elif " |
        grep -v "^    else" |
        grep -v "^    fi$" |
        sed -r 's/^[[:space:]]+(.*)/\1/g' |
        sed -r 's/^# (.*)/\x1b[32m\x1b[1m\n# \1\x1b[0m/' |
        sed -r 's/## (.*)/\x1b[33m## \1\x1b[0m/' |
        sed -r 's/-- -/-/' |
        sed -r 's/alias -g/alias/' |
        sed -r 's/^alias (-g )?([A-Za-z0-9!=._-]+)=(.*)/\x1b[36m\2\x1b[0m\t\3/g' |
        awk 'BEGIN { FS = "\t" } ; { printf "%-30s %s\n", $1, $2}' |
        sed -r "s/'(.*)'/\1/" |
        sed -r 's/"(.*)"/\1/'
    echo ""
    echo "\x1b[32m\x1b[1m\n# Functions\x1b[0m"

    cat "${DOTFILES_PATH}/zsh/functions.zsh" |
        grep "^function" -B1 |
        grep -v "^--" |
        awk '{printf "%s%s",$0,NR%2?"\t":"\n" ; }' |
        awk -F'\t' '{ t = $1; $1 = $2; $2 = t; print; }' |
        sed -r 's/^function ([A-Za-z0-9!=._-]+)(.*) # (.*)/\x1b[36m\1\x1b[0m\t\x1b[33m\3\x1b[0m/g' |
        awk 'BEGIN { FS = "\t" } ; { printf "%-35s %s\n", $1, $2}'
    echo ""
}

# Opens the current directory in Sublime Text, otherwise opens the given location
function open-with-sublime-text() {
    if [ $# -eq 0 ]; then
        subl -a .;
    else
        subl -a "$@";
    fi;
}

# Opens the current directory in Atom, otherwise opens the given location
function open-with-atom() {
    if [ $# -eq 0 ]; then
        atom .;
    else
        atom "$@";
    fi;
}

# Opens the current directory in Vim, otherwise opens the given location
function open-with-vim() {
    if [ $# -eq 0 ]; then
        vim .;
    else
        vim "$@";
    fi;
}

# Passthru grep
function grep-passthru() {
    if [ -z "$2" ]; then
        egrep "$1|$"
    else
        egrep "$1|$" $2
    fi
}

# Highlight a match in given color
function highlight() {
    declare -A fg_color_map
    fg_color_map[black]=30
    fg_color_map[red]=31
    fg_color_map[green]=32
    fg_color_map[yellow]=33
    fg_color_map[blue]=34
    fg_color_map[magenta]=35
    fg_color_map[cyan]=36

    fg_c=$(echo -e "\e[1;${fg_color_map[$1]}m")
    c_rs=$'\e[0m'
    sed -u s"/$2/$fg_c\0$c_rs/g"
}

# Commands usage statistics
function history-stats() {
    fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n25
}

# Human readable path variable
function path() {
    LF=$(printf '\\\012_')
    LF=${LF%_}

    echo $PATH | sed 's/:/'"$LF"'/g'
}

# Recursively fix dir/file permissions on a given directory
function fix-dir-perm() {
    if [ -d $1 ]; then
        find $1 -type d -exec chmod 755 {} \;
        find $1 -type f -exec chmod 644 {} \;
    else
        echo "$1 is not a directory."
    fi
}
