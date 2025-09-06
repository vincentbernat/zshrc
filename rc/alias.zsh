# -*- sh -*-

# Autoexpand some aliases
typeset -ga _vbe_abbrevations
abbrev-alias() {
    alias $1
    _vbe_abbrevations+=(${1%%\=*})
}
_vbe_zle-autoexpand() {
    local -a words; words=(${(z)LBUFFER})
    if (( ${#_vbe_abbrevations[(r)${words[-1]}]} )); then
        zle _expand_alias
    fi
    zle magic-space
}
zle -N _vbe_zle-autoexpand
bindkey -M emacs " " _vbe_zle-autoexpand
bindkey -M emacs "^ " magic-space
bindkey -M isearch " " magic-space

# Some generic aliases
alias df='df -h'
alias du='du -h'
alias rm='rm -i' # -I would be interesting, but it's not available on all implementations
alias mv='mv -i'
alias chown='chown -h'
alias chgrp='chgrp -h'
abbrev-alias tailf='tail -F'           # not shipped in util-linux anymore
alias reexec="exec ${ZSH_ARGZERO+-a $ZSH_ARGZERO} $SHELL"
alias q="exit"

(( $+commands[gdb] )) && alias gdb='gdb -q'
(( $+commands[dragon-drop] )) && alias dragon-drop='dragon-drop -x'

# Fix typos
(( $+commands[git] )) && abbrev-alias gti=git
(( $+commands[grep] )) && abbrev-alias grpe=grep
(( $+commands[sudo] )) && abbrev-alias suod=sudo
(( $+commands[ssh] )) && abbrev-alias shs=ssh

(( $+commands[mpv] )) && (( $+commands[nmcli] )) && {
    # mpv with lower best resolution when on metered connection
    mpv() {
        local -a args
        local dev=$(ip --json -o route get 1.1.1.1 2> /dev/null | jq -r '.[0].dev')
        [[ -n $dev ]] \
            && nmcli -t -f GENERAL.METERED dev show $dev | grep -q :yes \
            && args=($args "--ytdl-format=bestvideo[height<=?720]+bestaudio/best")

        command mpv $args "$@"
    }
}

(( $+commands[ug] )) && alias ug="ug --no-confirm --view='${(Q)"${$(alias e)#e=}"}'"

# ls
alias ll='ls -ltrhA'
if ls --color=auto --g -d . &> /dev/null; then
    # GNU ls
    if (( ${terminfo[colors]:-0} >= 8 )); then
        export LS_COLORS='ex=00:su=00:sg=00:ca=00:'
        alias ls='ls --color=auto --group-directories'
    else
        unset LS_COLORS
        alias ls='ls --group-directories -p' # -p = indicator for directories
    fi
elif ls -G -d . &> /dev/null; then
    # FreeBSD ls
    if (( ${terminfo[colors]:-0} >= 8 )); then
        export LSCOLORS="Gxfxcxdxbxegedabagacad"
        alias ls='ls -G'
    else
        unset LSCOLORS
        alias ls='ls -p'
    fi
else
    alias ls='ls -p'
fi

# System init-related aliases
() {
    local cmd
    local -a cmds
    cmds=(start stop reload restart status)

    if [[ -d /run/systemd/system ]]; then
        # systemd
        for cmd ($cmds) {
            abbrev-alias $cmd="${(%):-%(#..sudo )}systemctl $cmd"
            abbrev-alias u$cmd="systemctl --user $cmd"
        }
            else
                # generic service
                for cmd ($cmds) {
                    function $cmd() {
                        name=$1 ; shift
                        ${(%):-%(#..sudo)} service $name $0 "$@"
                    }
                    (( $+functions[compdef] )) && compdef _services $cmd
                }
                fi

}

# diff colors
(( $+commands[diff] )) \
    && (( ${terminfo[colors]:-0} >= 8 )) \
    && diff --color=auto --help &>/dev/null \
    && alias diff='diff --color=auto'

# ip aliases
(( $+commands[ip] )) && [[ $(zstat +link -- $commands[ip]) != */busybox ]] && {
    (( ${terminfo[colors]:-0} >= 8 )) && ip -color=auto -human rule &> /dev/null && \
        alias ip='ip -color=auto -human'
    abbrev-alias ip6='ip -6'
    abbrev-alias ipr='ip -resolve'
    abbrev-alias ip6r='ip -6 -resolve'
    abbrev-alias ipm='ip -resolve monitor'
    abbrev-alias ipb='ip -brief'
    abbrev-alias ip6b='ip -6 -brief'
}

# Other simple aliases
(( $+commands[xdg-app-chooser] )) && alias o=xdg-app-chooser
(( $+commands[irb] )) && alias irb='irb --readline -r irb/completion'
(( $+commands[tzdiff] )) && alias tzdiff='tzdiff $(( LINES - 4 ))'
(( $+commands[gcal] )) \
    && cal() {
        case $# in
            0) cal -i .+ ;;
            *)
                GCALANSI=1 gcal \
                    -H "\033[0;44m:\033[0m:\033[32m:\033[0m" \
                    --cc-holidays=FR \
                    --with-week-number --iso-week-number=yes \
                    --starting-day=1 "$@"
                ;;
        esac
    }
(( $+commands[mtr] )) && abbrev-alias mtrr='mtr -wzbe'
(( $+commands[ag] )) && (( $+commands[less] )) && alias ag='ag --pager="less -FRX"'
(( $+commands[pass] )) && alias pass='PASSWORD_STORE_ENABLE_EXTENSIONS=true pass'
(( $+commands[dig] )) && alias dig='dig +noall +answer'
(( $+commands[fdfind] )) && alias fd=fdfind
(( $+commands[nsxiv] )) && alias sxiv=nsxiv
alias clear='clear && [[ -n $TMUX ]] && tmux clear-history || true'

mkcd() {
    command mkdir -p -- $@ && cd -- ${@:$#}
}

# grep aliases
() {
    # If GNU grep is available, use it
    local grep=grep
    (( $+commands[ggrep] )) && grep=ggrep # GNU grep

    # Check if grep supports colors
    local colors="--color=auto"
    $grep -q $colors . <<< yes 2> /dev/null || colors=""

    # Declare aliases
    alias grep="command ${grep} ${colors}"
    abbrev-alias rgrep="grep -r"
    abbrev-alias egrep="grep -E"
    abbrev-alias fgrep="grep -F"
    # --color=auto doesn't work. See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=792135
    (( $+commands[zgrep] )) && alias zgrep="GREP=${grep} command zgrep ${colors}"
}

# Import a secret into an environment variable
secret() {
    for s in $@; do
        print -n "$s: "
        < /dev/tty IFS= read -rs $s
        print
        export $s
    done
}

# Isolate using bwrap
# - isolate (get a shell with only current directory writable)
# - isolate --share-net (same but get network access)
# - isolate --bind /tmp/.X11-unix{,} --bind /dev/dri{,} (insecure X11 access)
# - isolate ls (run ls in a sandbox)
# - isolate --share-net -- ping 1.1.1.1 (ping 1.1.1.1)
(( $+commands[bwrap] )) && isolate() {
    local -a options moreoptions nocwd
    options=(
        --ro-bind /{,}
        --dev /dev
        --proc /proc
        --tmpfs /run
        --tmpfs /tmp
        --tmpfs /var/tmp
        --tmpfs $HOME
        --ro-bind $HOME/.nix-profile{,}
        --unshare-all
        --die-with-parent
    )
    [[ -n $XDG_RUNTIME_DIR ]] && options=($options --tmpfs $XDG_RUNTIME_DIR)
    [[ -L /etc/resolv.conf ]] && options=($options --ro-bind ${${:-/etc/resolv.conf}:A}{,})
    case $1 in
        (--*)
            while [[ $# -gt 0 ]] && [[ $1 != "--" ]]; do
                case $1 in
                    (--no-cwd) nocwd=1 ;;
                    (*) moreoptions=($moreoptions $1) ;;
                esac
                shift
            done
            [[ $1 == "--" ]] && shift
            ;;
    esac
    [[ -z $nocwd ]] && [[ $PWD != $HOME ]] && options=($options --bind $PWD{,})
    options=($options $moreoptions)
    if [[ $# -eq 0 ]]; then
        options=(
            $options
            --ro-bind $HOME/.zsh{,}
            --ro-bind $HOME/.zshrc{,}
            --ro-bind $HOME/.zshenv{,}
            --tmpfs $ZSHRUN
            --setenv VBE_SHELL_ISOLATED true
            --
            zsh -i
        )
    else
        options=($options -- "$@")
    fi
    bwrap $options
}

# Isolated commands
(( $+commands[claude] )) && \
    claude() {
        local -a args
        args=(
            --share-net
            --bind ~/.config/claude-code{,}
            --overlay-src $GOPATH --tmp-overlay $GOPATH
        )
        local agentmd=~/.config/agents.md/${${PWD#$HOME/}//\//-}.md
        [[ -f $agentmd ]] && {
            mkdir $HOME/tmp/overlaywd-$$
            args=(
                $args
                --no-cwd
                --bind $HOME{,}
                --bind $agentmd /tmp/o1/CLAUDE.md
                --
                bwrap --overlay-src /tmp/o1 --overlay $PWD $HOME/tmp/overlaywd-$$ $PWD
                --
                bwrap --tmpfs $HOME --bind $PWD{,}
            )
        }
        args=(
            $args
            --
            env SHELL=/bin/bash CLAUDE_CONFIG_DIR=$HOME/.config/claude-code
        )
        isolate $args bash "$@"
    }
(( $+commands[gemini] )) && \
    alias gemini='isolate --share-net --bind ~/.gemini{,} \
      --bind-try ~/.config/agents.md/${${PWD#$HOME/}//\//-}.md $PWD/GEMINI.md \
      --overlay-src $GOPATH --tmp-overlay $GOPATH \
      -- =gemini'

# git
(( $+commands[git] )) && abbrev-alias gls="git ls-files"
(( $+commands[emacsclient] * $+commands[git] )) && magit() {
        local root=$(git rev-parse --show-toplevel)
        [[ -n $root ]] || return
        emacsclient -e "(progn
                    (select-frame-set-input-focus
                      (window-frame
                        (get-buffer-window
                           (magit-status \"${root}\"))))
                    (delete-other-windows))"
}

# smv like scp
alias smv='rsync -P --remove-source-files'

# Like sudo -sE but it preserves ZDOTDIR, see:
#  <https://sources.debian.org/src/sudo/1.9.1-1/plugins/sudoers/env.c/?hl=187#L187>
suzsh() command sudo -H -u ${1:-root} \
    env ZDOTDIR=${ZDOTDIR:-$HOME} \
    ZSH=$ZSH \
    ${DISPLAY+DISPLAY=$DISPLAY} \
    ${SSH_TTY+SSH_TTY=$SSH_TTY} \
    ${SSH_AUTH_SOCK+SSH_AUTH_SOCK=$SSH_AUTH_SOCK} \
    ${ZSH_NAME} -i -l

# Newline Delimited JSON pretty-printing.
#
# Many programs have a flag to enable unbuffered output. For example,
# `curl -N`. Most programs can be forced to use unbuffered output with
# `stdbuf -o L`.
(( $+commands[python] + $+commands[python3] )) && \
    ndjson() {
        local -a pythons
        pythons=(/usr/{,local/}bin/python{3,,2}(XN) $commands[python3] $commands[python])
        ${pythons[1]} -u -c '#!/usr/bin/env python3

# Pretty-print files containing JSON lines. Reads from stdin when no
# argument is provided, otherwise pretty print each argument. This
# script should be invoked with "-u" to disable buffering. The shebang
# above is just for syntax highlighting to work correctly.

import sys
import re
import json
import subprocess
import errno
try:
    import pygments
    try:
        from pygments.lexers import JsonLexer
    except ImportError:
        from pygments.lexers import JavascriptLexer as JsonLexer
    from pygments.formatters import TerminalFormatter
except ImportError:
    pygments = None

jsonre = re.compile(r"(?P<prefix>.*?)(?P<json>\{.*\}|\[.*\])(?P<suffix>.*)")

def display(f):
    pager = None
    out = sys.stdout
    if out.isatty() and f != sys.stdin:
        pager = subprocess.Popen(["less", "-RFX"],
                                 stdin=subprocess.PIPE,
                                 encoding="utf-8", errors="replace")
        out = pager.stdin
    while True:
        line = f.readline()
        if line == "":
            break
        mo = None
        try:
            mo = jsonre.match(line)
            if not mo:
                raise ValueError("No JSON string found")
            j = json.loads(mo.group("json"))
            pretty = json.dumps(j, indent=2)
            if pygments and sys.stdout.isatty():
                pretty = pygments.highlight(pretty,
                                            JsonLexer(),
                                            TerminalFormatter())
            output = (mo.group("prefix") + pretty.strip() +
                      mo.group("suffix") + "\n")
        except:
            output = line
        try:
            out.write(output)
        except BrokenPipeError:
            break
    if pager is not None:
        try:
            pager.stdin.close()
        except BrokenPipeError:
            pass
        pager.wait()

if len(sys.argv) == 1:
    files = [sys.stdin]
else:
    files = sys.argv[1:]

for f in files:
    try:
        if f != sys.stdin:
            with open(f) as f:
                display(f)
        else:
            display(f)
    except KeyboardInterrupt:
        sys.exit(1)
' "$@"
}

(( $+commands[xmllint] )) && xml() {
        cat "$@" | xmllint --format - | v
}

v() {
    case $(file --brief --mime-type $1 2> /dev/null) in
        image/svg+xml) ;;
        image/*)
            (( $+commands[nsxiv] )) && ${I3SOCK+i3-tabbed} nsxiv $1
            return
            ;;
        video/*)
            (( $+commands[mpv] )) && ${I3SOCK+i3-tabbed} mpv --no-fs $1
            return
    esac
    if (( $+commands[bat] )); then
        if (( ! $# )); then
            gzip -cdfq | bat
        else
            for f in "$@"; do
                gzip -cdfq -- $f | bat --file-name ${f%.gz}
            done
        fi
    elif (( $+commands[less] )); then
        gzip -cdfq -- "$@" | less -FX
    elif (( $+commands[zmore] )); then
        zmore "$@"
    elif (( $+commands[more] )); then
        gzip -cdfq -- "$@" | more
    else
        gzip -cdfq -- "$@"
    fi
}

# Prepare a command to record a video:
#   screenrecord out.mkv
#
# To insert a line in a middle of a command, you can use C-v C-j. If
# you want to grab sound, you can add "-f pulse -ac 1 -i default"
# (replace "default" with the name of an input you can get with "pactl
# list sources | grep Name".
#
# It uses lossless compression. This can be compressed again with:
#   ffmpeg -i out.mkv -c:v libx264 -qp 0 -preset veryslow out-smaller.mkv
# For non lossless compression:
#   ffmpeg -i out.mkv -c:v libx264 -crf 18 -preset veryslow -tune stillimage out-smaller.mkv
screenrecord() {
    local x y width height border
    eval $(slop -b 5 -l -c 0.3,0.4,0.6,0.4 -f 'x=%x y=%y width=%w height=%h window=%i')
    [[ -n $x ]] || return
    [[ -z $window ]] || {
        border=$(xwininfo -id $window | sed -n 's/  Border width: //p')
        (( x += border ))
        (( y += border ))
        (( width -= border*2 ))
        (( height -= border*2 ))
    }
    print -z -- ffmpeg \
        \\\\$'\n' \
        -f x11grab \
        -draw_mouse 0 \
        -r 30 \
        -s $((${width} / 2 * 2))x$((${height} / 2 * 2)) \
        -i ${DISPLAY}+${x},${y} \
        \\\\$'\n' \
        -pix_fmt yuv420p \
        -c:v libx264 \
        -qp 0 \
        -preset ultrafast \
        \\\\$'\n' \
        $@
}

# Reimplementation of an xterm tool
(( $+commands[resize] )) || resize() {
        local previous=$(stty -g)
        local rows
        local cols
        stty raw -echo min 0 time 1 # timeout: 1th of second
        printf '\0337\033[r\033[999;999H\033[6n\0338'
        IFS='[;R' read -r _ rows cols _ || true
        stty $previous
        stty cols $cols rows $rows
    }

# Simple calculator
if (( $+commands[qalc] )); then
    aliases[=]='noglob qalc'
else
    function _vbe_calc() {
        autoload -Uz zcalc
        echo $(($@))
    }
    aliases[=]='noglob _vbe_calc'
fi
(( $+commands[units] )) && alias units='noglob units --verbose'

# Allow to prefix commands with `$` to help copy/paste operations.
function \$() {
    "$@"
}

# Get my own external IP
function myip() {
    local -a get
    (( $+commands[wget] )) && get=(wget -q -O - -T 1)
    (( $+commands[curl] )) && get=(curl -s --max-time 1)
    for v in 4 6 ; do
        echo IPv$v \
            $($get -$v https://vincent.bernat.ch/ip || echo "unknown")
    done 2> /dev/null
}

# Send a line to Android device using adb. This is a bit broken as we
# should escape "%s", but it is not escapable. "%%s" would just output
# "% ".
(( $+commands[adb] )) && function adbtype() {
        local line
        case $# in
            0)
                while IFS= read -r line || [[ -n $line ]]; do
                    adb shell input text ${(q)line}
                done
                ;;
            *)
                adb shell input text ${(q)${(j: :)@}}
                ;;
        esac
    }

# Cleanup various things on a system
function clean() {
    local prompt() {
        local what=$1
        local prompt="${(%):-%B}Clean $what?${(%):-%b}"
        read -sq "?$prompt "
        case $? in
            0)
                print -P "%F{green}yes%F{default}"
                return 0
                ;;
        esac
        print -P "%F{red}no%F{default}"
        return 1
    }

    (( $+commands[apt] )) && prompt "system APT cache" && \
        sudo apt clean
    [[ -d /var/cache/pbuilder/aptcache ]] && prompt "pbuilder APT cache" && \
        sudo find /var/cache/pbuilder/aptcache -type f -delete
    ()(($#)) /var/cache/pbuilder/build/cow*(N/) && prompt "pbuilder old build" && \
        sudo rm -rf --one-file-system /var/cache/pbuilder/build/cow*
    ()(($#)) ~/.cache/sbuild/*.tar(Nm+30) && prompt "old sbuild chroot" && \
        rm -f ~/.cache/sbuild/*.tar(Nm+30)
    (( $+commands[docker] )) && prompt "Docker related stuff" && \
        sudo =docker system prune -f
    (( $+commands[podman] )) && prompt "Podman related stuff" && \
        podman system prune -f
    [[ -d /nix ]] && prompt "nix store" && \
        nix-collect-garbage --delete-older-than 7d
    [[ -d /var/log/journal ]] && prompt "journal logs" && \
        sudo journalctl --vacuum-time='2 months'
    [[ -n ${GOMODCACHE:-$GOPATH} ]] && [[ -d ${GOMODCACHE:-$GOPATH} ]] && {
        prompt "Go module cache" && go clean -modcache
        touch ${GOMODCACHE:-$GOPATH}
    }
    local d
    for d in tmp src download; do
        [[ -d ~/$d ]] && prompt "user $d directory" && \
            find ~/$d -maxdepth 1 -mindepth 1 -type d -mtime +60 -print0 | xargs -0r rm -rf && \
            find ~/$d -maxdepth 1 -mindepth 1 -type f -mtime +60 -delete
    done
}

# Update various things
update() {
    (( $+commands[apt] )) \
        && sudo apt update \
        && apt list --upgradable \
        && apt -s upgrade 2> /dev/null | command grep -q '^Inst ' \
        && sudo apt upgrade \
        && sudo apt autoremove
    # Other Debian-related stuff:
    #  - aptitude purge \~o: purge obsolete packages
    #  - aptitude purge \~c: purge uninstalled packages
    (( $+commands[flatpak] )) && flatpak update && flatpak uninstall --unused
    (( $+commands[nix-channel] )) && [[ -s ~/.nix-channels ]] && nix-channel --update
    (( $+commands[nix] )) && nix registry pin nixpkgs
    (( $+commands[nix] )) && [[ -f ~/.config/nixpkgs/flake.nix ]] \
        && nix flake update --flake ~/.config/nixpkgs
    # Alternative would be to "nix registry pin nixpkgs"?
    (( $+commands[home-manager] )) && nice home-manager switch
    # (( $+commands[doom] )) && [[ -d ~/.config/doom ]] && doom sync -u
    (( $+commands[fwupdmgr] )) && fwupdmgr update
    [[ -f /run/reboot-required ]] && print -P "%F{red}*** %BReboot required%b ***%F{default}"
}

# Display a color testcard
# From: http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
colortest() {
    local T='gYw'   # The test text

    local fg
    local bg
    printf "%4s" ""
    for fg in "" {40..47}; do
	    printf "%7sm" ${fg}
    done
    printf "\n"
    for fg in 0 1 $(for i in {30..37}; do echo $i 1\;$i; done); do
	    printf " %5s \e[%s  %s  " ${fg} ${fg}m ${T}
	    for bg in {40..47}m; do
	        printf " \e[%s\e[%s  %s  \e[0m" ${fg}m ${bg} ${T}
	    done
	    printf "\n"
    done
    printf "\n"

    printf "Color cube: 6x6x6:\n"
    local red
    local green
    local blue
    for red in {0..5}; do
        for green in {0..5}; do
            for blue in {0..5}; do
                bg=$((16 + red * 36 + green * 6 + blue))
                printf "\e[48;5;%dm  " bg
            done
            printf "\e[0m "
        done
        printf "\n"
    done

    printf "Grayscale ramp:\n"
    for bg in {232..255}; do
        printf "\e[48;5;%dm  " bg
    done
    printf "\e[0m\n"

    # See: https://gist.github.com/XVilka/8346728
    printf "True colors:\n"
    local r g b colnum
    for colnum in {0..76}; do
        r=$((255 - colnum*255/76))
        g=$((colnum*510/76))
        b=$((colnum*255/76))
        (( g <= 255 )) || g=$((510 - g))
        printf "\e[48;2;%d;%d;%dm " r g b
    done
    printf "\e[0m\n"
}

# We provide an enhanced cowbuilder command.  It will mimic a bit what
# git-pbuilder is doing. Here are the features:
#
#   1. It will use /var/cache/pbuilder/base-$DIST-$ARCH.cow.
#   2. It will take as first argument something like $DIST/$ARCH.
#   3. If $DIST contains an hyphen, some special rules may be
#      applied. Currently, if it ends with -backports, the backports
#      mirror will be added.
#
# Note: have a look at cowbuilder-dist in ubuntu-dev-tools which is
# similar. Also, the layout is compatible with git-pbuilder from
# git-buildpackage package.

(( $+commands[cowbuilder] )) && {
    cowbuilder() {

        # Usage
        (( $# > 0 )) || {
            print -u2 "$0 distrib[/arch] ..."
            return 1
        }

        # Architecture
        local distrib
        local arch
        case $1 in
            */*)
                arch=${1#*/}
                distrib=${1%/*}
                ;;
            *)
                distrib=$1
                ;;
        esac
        shift
        local -a opts

        if [[ -z $arch ]] || [[ $arch == $(dpkg-architecture -q DEB_BUILD_ARCH) ]]; then
            opts=(--debootstrap debootstrap)
        else
            case $arch,$(dpkg-architecture -q DEB_BUILD_ARCH) in
                i386,amd64)
                    opts=(--debootstrap debootstrap)
                    ;;
                *)
                    # Needs qemu-user-static
                    opts=(--debootstrap qemu-debootstrap)
                    ;;
            esac
        fi

        # Distribution
        local -a debians ubuntus
        ubuntus=(/usr/share/debootstrap/scripts/*(e,'[ ${REPLY}(:A) = /usr/share/debootstrap/scripts/gutsy ]',))
        ubuntus=(${ubuntus##*/})
        debians=(/usr/share/debootstrap/scripts/*(e,'[ ${REPLY}(:A) = /usr/share/debootstrap/scripts/sid ]',))
        debians=(${debians##*/})
        if [[ ${debians[(r)${distrib%%-*}]} == ${distrib%%-*} ]]; then
            opts=($opts --mirror http://deb.debian.org/debian)
            opts=($opts
                  --debootstrapopts --keyring
                  --debootstrapopts /usr/share/keyrings/debian-archive-keyring.gpg)
        elif [[ ${ubuntus[(r)${distrib%%-*}]} == ${distrib%%-*} ]]; then
            local mirror=http://archive.ubuntu.com/ubuntu
            opts=($opts --mirror $mirror)
            opts=($opts
                  --debootstrapopts --keyring
                  --debootstrapopts /usr/share/keyrings/ubuntu-archive-keyring.gpg)
            opts=($opts --components 'main universe')
            opts=($opts --othermirror "deb ${mirror} ${distrib%%-*}-updates main universe")
            case ${distrib%%-*} in
                precise|trusty|xenial)
                    opts=($opts --extrapackages pkg-create-dbgsym)
                    ;;
            esac
        fi

        # Flavor
        case ${distrib} in
            *-backports-sloppy)
                opts=($opts --othermirror "deb http://deb.debian.org/debian ${distrib%-sloppy} main|deb http://deb.debian.org/debian ${distrib} main")
                ;;
            *-backports)
                opts=($opts --othermirror "deb http://deb.debian.org/debian ${distrib} main")
                ;;
        esac

        local target
        if [[ -n $arch ]]; then
            target=$distrib-$arch
            opts=($opts --debootstrapopts --arch --debootstrapopts $arch)
        else
            target=$distrib
        fi

        sudo --preserve-env=DEB_BUILD_OPTIONS env DEBIAN_BUILDARCH="$arch" cowbuilder $1 \
            --distribution ${distrib%%-*}  \
            --basepath /var/cache/pbuilder/base-${target}.cow \
            --buildresult $PWD \
            $opts $*[2,$#]
    }
}

# Python-related aliases
(( $+commands[python3] )) && ! (( $+commands[python] )) && alias python=python3
(( $+commands[ipython3] )) && \
    alias ipython=ipython3 && \
    alias ipython3='command ipython3 --no-confirm-exit'

(( $+commands[pip] )) && alias pip='PIP_REQUIRE_VIRTUALENV=true python -m pip --disable-pip-version-check'

# Virtualenv related functions
# Simplified version of virtualenvwrapper.
typeset -g WORKON_HOME=${WORKON_HOME:-~/.virtualenvs}
_virtualenv () {(
    emulate -L zsh
    setopt errexit
    local interpreter
    local venv
    local -i delete_on_exit=0
    case $1 in
        2) interpreter=python2 ;;
        3) interpreter=python3 ;;
        *) interpreter=python ;;
    esac
    shift
    [[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME
    pushd $WORKON_HOME > /dev/null || return

    case ${@[-1]} in
        tmp)
            venv=tmp$$
            delete_on_exit=1
            ;;
        *) venv=$1 ;;
    esac
    {
        if command $interpreter -c "import virtualenv" 2> /dev/null; then
            command $interpreter -m virtualenv -p $interpreter "${@[0,-2]}" $venv
        else
            command $interpreter -m venv "${@[0,-2]}" $venv
        fi
        cat <<EOF >&2
# To reuse the environment for Node.JS, use:
#  \$ pip install nodeenv
#  \$ nodeenv -p -n system

EOF
    } always {
	    popd > /dev/null || return
    }
    workon $venv
    (( delete_on_exit )) && \
        rm -rf $WORKON_HOME/$venv
)}

alias virtualenv2='_virtualenv 2'
alias virtualenv3='_virtualenv 3'
(( $+commands[python2] )) && alias virtualenv='_virtualenv 2'
(( $+commands[python3] )) && alias virtualenv='_virtualenv 3'
