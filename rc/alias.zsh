# -*- sh -*-

# Some generic aliases
alias df='df -h'
alias du='du -h'
alias rm='rm -i'
alias mv='mv -i'
alias ll='ls -ltrh'
alias chown='chown -h'
alias chgrp='chgrp -h'
alias tailf='tail -F'           # not shipped in util-linux anymore
() {
  local dmesg_version=${${${:-"$(dmesg --version 2> /dev/null)"}##* }:-0.0}
  if is-at-least 2.23 $dmesg_version; then
      alias dmesg='dmesg -H -P'
  elif is-at-least 0.1 $dmesg_version; then
    alias dmesg='dmesg -T'
  fi
}
(( $+commands[gdb] )) && alias gdb='gdb -q'

# ls colors
(( ${terminfo[colors]:-0} >= 8 )) && {
  if ls --color=auto -d . &>/dev/null; then
      export LS_COLORS='ex=00:su=00:sg=00:ca=00:'
      alias ls='ls --color=auto'
  elif ls -G &> /dev/null; then
      export LSCOLORS="Gxfxcxdxbxegedabagacad"
      alias ls='ls -G'
  fi
}

# diff colors
(( $+commands[diff] )) \
    && (( ${terminfo[colors]:-0} >= 8 )) \
    && diff --color=auto --help &>/dev/null \
    && alias diff='diff --color=auto'

# ip aliases
(( $+commands[ip] )) && {
  (( ${terminfo[colors]:-0} >= 8 )) && ip -color -human rule > /dev/null 2> /dev/null && \
      alias ip='ip -color -human'
  alias ip6='ip -6'
  alias ipr='ip -resolve'
  alias ip6r='ip -6 -resolve'
  alias ipm='ip -resolve monitor'
  alias ipb='ip -brief'
  alias ip6b='ip -6 -brief'
}

# Other simple aliases
(( $+commands[xdg-open] )) && alias o=xdg-open
(( $+commands[xdg-app-chooser] )) && alias o=xdg-app-chooser
(( $+commands[irb] )) && alias irb='irb --readline -r irb/completion'
(( $+commands[ipython] )) && alias ipython2=\=ipython # maybe inexact
(( $+commands[ipython3] )) && alias ipython=ipython3
(( $+commands[pip] )) && alias pip='PIP_REQUIRE_VIRTUALENV=true pip --disable-pip-version-check'
(( $+commands[pip3] )) && alias pip3='PIP_REQUIRE_VIRTUALENV=true pip3 --disable-pip-version-check'
(( $+commands[scapy3] )) && alias scapy=scapy3
(( $+commands[tzdiff] )) && alias tzdiff='tzdiff $(( LINES - 3 ))'
(( $+commands[ncal] )) && alias ncal='ncal -w'
(( $+commands[docker] )) && alias indocker='docker run -it --rm -w "$(pwd)" -v "$(pwd):$(pwd)" -u "$(id -u):$(id -g)"'
(( $+commands[git] )) && alias gti=git
(( $+commands[mtr] )) && alias mtrr='mtr -wzbe'
(( $+commands[tmate] )) && alias tmate='env -u TMUX tmate'
(( $+commands[ag] )) && alias ag='ag --pager="less -FRX"'
alias clear='clear && [[ -n $TMUX ]] && tmux clear-history || true'
mkcd() { command mkdir -p $1 && cd $1 }
(( $+commands[nix-shell] )) && nix-zsh() {
        case ${#${@:#-*}} in
            0) nix-shell --command zsh "$@" ;;
            *) nix-shell --command zsh -p glibcLocales "$@" ;;
        esac
}

# Global aliases. I am using `,' as a prefix.
alias -g ,nd='*(/om[1])'        # newest directory
alias -g ,ndd='*(/om[1])'       # before-newest directory
alias -g ,nf='*(.om[1])'        # newest file
alias -g ,nff='*(.om[1])'       # before-newest file
alias -g ,silent="> /dev/null 2>&1"
alias -g ,noerr="2> /dev/null"

# Setting up less colors
(( ${terminfo[colors]:-0} >= 8 )) && {
  export LESS_TERMCAP_mb=$'\E[1;31m'
  export LESS_TERMCAP_md=$'\E[1;38;5;74m'
  export LESS_TERMCAP_me=$'\E[0m'
  export LESS_TERMCAP_se=$'\E[0m'
  export LESS_TERMCAP_so=$'\E[1;3;246m'
  export LESS_TERMCAP_ue=$'\E[0m'
  export LESS_TERMCAP_us=$'\E[1;32m'
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
  alias rgrep="grep -r"
  alias egrep="grep -E"
  alias fgrep="grep -F"
  # --color=auto doesn't work. See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=792135
  (( $+commands[zgrep] )) && alias zgrep="GREP=${grep} command zgrep ${colors}"
}

# smv like scp
alias smv='rsync -P --remove-source-files'
(( $+functions[compdef] )) && compdef _ssh smv=scp

# Like sudo -sE but it preserves ZDOTDIR, see:
#  <https://sources.debian.org/src/sudo/1.9.1-1/plugins/sudoers/env.c/?hl=187#L187>
suzsh() {
    ZDOTDIR=${ZDOTDIR:-$HOME} command sudo \
            --preserve-env=ZDOTDIR \
            -sE -u ${1:-root}
}

# JSON pretty-printing.
#
# Many programs have a flag to enable unbuffered output. For example,
# `curl -N`. Most programs can be forced to use unbuffered output with
# `stdbuf -o L`.
(( $+commands[python] + $+commands[python3] )) && \
json() {
  local -a pythons=(/usr/{,local/}bin/python{3,,2}(XN) $commands[python3] $commands[python])
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
        except IOError as e:
            if e.errno == errno.EPIPE or e.errno == errno.EINVAL:
                break
            raise
    if pager is not None:
        pager.stdin.close()
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

(( $+functions[json] )) && \
jsonf() {
  tail -f "$@" | json
}

# Image display
if (( $+commands[convert] )); then
    image() {
        local col row dummy red green blue rest1 rest2 previous current max first
        local -a upper lower
        max=256
        first=1
        convert -thumbnail ${COLUMNS}x$((LINES*2 - 4)) $1 txt:- | \
            while IFS=',:() ' read col row dummy red green blue rest1 rest2; do
                # ImageMagick pixel enumeration: 85,68,65535,rgba
                [[ $first == 1 ]] && [[ $col == "#" ]] && \
                  [[ $row == "ImageMagick" ]] && max=$rest1
                first=0
                [[ $col == "#" ]] && continue
                if (( $#upper > 0 && row%2 == 0 && col == 0 )); then
                    for i in {1..$#upper}; do
                        current=$(printf "\e[38;2;%s;48;2;%sm" $upper[$i] $lower[$i])
                        if [[ $current == $previous ]]; then
                            printf "▀"
                        else
                            printf "$current▀"
                        fi
                        previous=$current
                    done
                    printf "\e[0m\e[K\n"
                    upper=()
                    lower=()
                    previous=
                fi
                (( $max == 256 )) || {
                    red=$(( red*256/max ))
                    green=$(( green*256/max ))
                    blue=$(( blue*256/max ))
                }
                if [[ $((row%2)) = 0 ]]; then
                    upper=($upper "$red;$green;$blue")
                else
                    lower=($lower "$red;$green;$blue")
                fi
            done
        (( $#upper == 0 )) || {
            for i in {1..$#upper}; do
                printf "\e[38;2;%sm▀" $upper[$i]
            done
            printf "\e[0m\e[K\n"
        }
    }
else
    image() {
        >&2 print "ImageMagick needed to display images"
        return 1
    }
fi

xml() {
    cat "$@" | xmllint --format -
}

v() {
    case $(file --brief --mime-type $1 2> /dev/null) in
        image/*)
            image $1
            return
            ;;
    esac
    (( $+commands[emacsclient] )) && [[ -S /tmp/emacs$UID/server ]] && [[ -O /tmp/emacs$UID/server ]] && {
        emacsclient -t -e "(view-buffer (find-file-noselect \"$1\") 'vbe:kill-buffer-and-frame)"
        return
    }
    zless -FX "$@"
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
# Remove "-qp 0" for non-lossless compression.
#
screenrecord() {
  local X Y WIDTH HEIGHT BORDER
  eval $(xwininfo -id $(xdotool selectwindow) | \
             sed -n \
                 -e 's/ *Absolute upper-left X: *\([0-9]*\)/X=\1/p' \
                 -e 's/ *Absolute upper-left Y: *\([0-9]*\)/Y=\1/p' \
                 -e 's/ *Width: *\([0-9]*\)/WIDTH=\1/p' \
                 -e 's/ *Height: *\([0-9]*\)/HEIGHT=\1/p' \
                 -e 's/ *Border width: *\([0-9]*\)/BORDER=\1/p')
  print -z -- ffmpeg \
        \\\\$'\n' \
        -f x11grab \
        -draw_mouse 0 \
        -r 30 \
        -s $((${WIDTH} / 2 * 2))x$((${HEIGHT} / 2 * 2)) \
        -i ${DISPLAY}+$((X+BORDER)),$((Y+BORDER)) \
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
function \=() {
  echo $(($@))
}
aliases[=]='noglob ='           # not really supported: http://www.zsh.org/mla/workers/2016/msg00081.html
(( $+commands[units] )) && alias units='noglob units --verbose'
# Also, we can use zcalc
autoload -Uz zcalc

# Currency conversion
function currency() {
  local -a amounts
  local -a currencies
  for ((i=1; i<=$#; i++)); do
    case ${@[i]} in
      [0-9.]*)
        amounts=($amounts ${@[i]})
        ;;
      *)
        currencies=($currencies ${@[i]})
        ;;
    esac
  done
  (( $#currencies > 1 )) || currencies=($currencies eur usd)
  local from=${currencies[1]}
  local rate
  for amount in $amounts; do
    for to in $currencies; do
      from=${from:u}
      to=${to:u}
      [[ ${to} != ${from} ]] || continue
      #echo "Convert $amount ${from:u} to ${to:u}"
      rate=$(curl -s "https://free.currencyconverterapi.com/api/v6/convert?q=${from}_${to}&compact=ultra&apiKey=cdca335960c293ac5e8d" \
                 | sed -n 's/{.*:\(.*\)}/\1/p')
      printf "%.2f $from = %.2f $to\n" $amount $(( amount * rate))
    done
  done
}

# Allow to prefix commands with `$` to help copy/paste operations.
function \$() {
  "$@"
}

# Get my own external IP
function myip() {
  for v in 4 6 ; do
    echo IPv$v \
         $(curl -s -$v --max-time 1 https://vincent.bernat.ch/ip || echo "unknown")
  done 2> /dev/null
}

# Display a color testcard
# From: http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
colortest() {
    local T='gYw'   # The test text

    local fg
    local bg
    printf "%12s" ""
    for fg in {40..47}; do
	printf "%7sm" ${fg}
    done
    printf "\n"
    for fg in 0 1 $(for i in {30..37}; do echo $i 1\;$i; done); do
	printf " %5s \e[%s  %s  " ${fg}m ${fg}m ${T}
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
