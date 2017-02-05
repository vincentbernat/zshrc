# -*- sh -*-

# Some generic aliases
alias df='df -h'
alias du='du -h'
alias rm='rm -i'
alias ll='ls -l'
__() {
  local dmesg_version=${${${:-"$(dmesg --version 2> /dev/null)"}##* }:-0.0}
  if is-at-least 2.23 $dmesg_version; then
      alias dmesg='dmesg -H -P'
  elif is-at-least 0.1 $dmesg_version; then
    alias dmesg='dmesg -T'
  fi
} && __

# ls colors
(( ${terminfo[colors]:-0} >= 8 )) && {
    export LSCOLORS="Gxfxcxdxbxegedabagacad"
    ls --color -d . &>/dev/null && alias ls='ls --color=tty' || {
        ls -G &> /dev/null && alias ls='ls -G'
    }
}

# ip aliases
alias ip6='ip -6'
alias ipr='ip -r'
alias ip6r='ip -6 -r'
alias ipm='ip -r monitor'

# Other simple aliases
(( $+commands[cloudstack] )) && alias cs=cloudstack
(( $+commands[irb] )) && alias irb='irb --readline -r irb/completion'

# Setting up less colors
(( ${terminfo[colors]:-0} >= 8 )) && {
  export LESS_TERMCAP_mb=$'\E[1;31m'
  export LESS_TERMCAP_md=$'\E[1;38;5;74m'
  export LESS_TERMCAP_me=$'\E[0m'
  export LESS_TERMCAP_se=$'\E[0m'
  export LESS_TERMCAP_so=$'\E[1;3;5;246m'
  export LESS_TERMCAP_ue=$'\E[0m'
  export LESS_TERMCAP_us=$'\E[1;32m'
}

# grep
__() {
  local cmd
  local -A greps
  local colors="--color=auto"
  grep -q $colors . <<< yes 2> /dev/null || colors=""
  greps=(grep ""
         rgrep r
         egrep E
         fgrep F
         zgrep "")
  for cmd in ${(k)greps}; do
    if (( $+commands[$cmd] )); then
        alias $cmd="$cmd ${colors}"
    else
      [[ -n ${greps[$cmd]} ]] &&
          alias $cmd="command grep -${greps[$cmd]} ${colors}"
    fi
  done
} && __

# smv like scp
alias smv='rsync -P --remove-source-files'
(( $+functions[compdef] )) && compdef _ssh smv=scp

# Less generic aliases
susu() {
  command sudo -H -u ${1:-root} \
          env ZDOTDIR=${ZDOTDIR:-$HOME} \
              ZSH=$ZSH ${DISPLAY+DISPLAY=$DISPLAY} \
              ${SSH_TTY+SSH_TTY=$SSH_TTY} \
              ${SSH_AUTH_SOCK+SSH_AUTH_SOCK=$SSH_AUTH_SOCK} \
          zsh -i -l
}

# Aliases as a function
evince() { command evince ${*:-*.(djvu|dvi|pdf)(om[1])} }
mkcd() { command mkdir -p $1 && cd $1 }

# JSON pretty-printing.
#
# Many programs have a flag to enable unbuffered output. For example,
# `curl -N`. Most programs can be forced to use unbuffered output with
# `stdbuf -o L`.
json() {
  PATH=/usr/bin:$PATH python -u -c '#!/usr/bin/env python

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

jsonre = re.compile(r"(?P<prefix>.*?)(?P<json>\{.*\})(?P<suffix>.*)")


def display(f):
    pager = None
    out = sys.stdout
    if out.isatty() and f != sys.stdin:
        pager = subprocess.Popen(["less", "-RFX"], stdin=subprocess.PIPE)
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
        if type(f) != file:
            with file(f) as f:
                display(f)
        else:
            display(f)
    except KeyboardInterrupt:
        sys.exit(1)
' "$@"
}

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

# Other pretty-printing functions
if (( $+commands[pygmentize] )); then
  __pygmentize() {
    local formatter
    if (( ${terminfo[colors]:-0} >= 256 )); then
      formatter=console256
    else
      formatter=terminal
    fi

    PATH=/usr/bin:$PATH python -u -c "#!/usr/bin/env python
import sys
import os
import errno
import pygments.cmdline
null = open(os.devnull, 'wb')
sys.stderr = null
try:
    sys.exit(pygments.cmdline.main(sys.argv))
except KeyboardInterrupt:
    sys.exit(1)
except IOError as e:
    if e.errno == errno.EPIPE:
        sys.exit(1)
    raise
" -f $formatter -P style=monokai "$@"
  }

  xml() {
    cat "$@" | xmllint --format - | __pygmentize -l xml
  }

  v() {
    # Display as an image
    case $(file --brief --mime-type $1 2> /dev/null) in
      image/*) image $1 ; return ;;
    esac

    # Display in Emacs view-mode
    (( $+commands[emacsclient] )) && [[ -S /tmp/emacs$UID/server ]] && [[ -O /tmp/emacs$UID/server ]] && {
        emacsclient -t -e "(view-buffer (find-file-noselect \"$1\") 'vbe:kill-buffer-and-frame)"
        return
    }

    # Use pygmentize
    local lexer
    lexer=$(__pygmentize -N ${1%.gz})

    local -a args
    case $lexer in
      text)
        args=(-g $args)
        ;;
      *)
        args=(-l $lexer)
        ;;
    esac

    zcat -f "$@" | __pygmentize $args | less -RFX
  }
else
  xml() {
    cat "$@" | xmllint --format -
  }

  v() {
    case $(file --brief --mime-type $1 2> /dev/null) in
      image/*) image $1 ; return ;;
    esac
    zless -FX "$@"
  }
fi

# Record a video:
#   screenrecord out.mkv
#
# It uses lossless compression. This can be compressed again with:
#   ffmpeg -i out.mkv -c:v libx264 -qp 0 -preset veryslow out-smaller.mkv
#
# Remove "-qp 0" for non-lossless compression.
screenrecord() {
  (
    eval $(xdotool selectwindow getwindowgeometry --shell) &&
    command ffmpeg -f x11grab \
      -draw_mouse 0 \
      -r 30 \
      -s $((${WIDTH} / 2 * 2))x$((${HEIGHT} / 2 * 2)) \
      -i ${DISPLAY}.${SCREEN:-0}+${X:-0},${Y:-0} \
      -dcodec copy \
      -pix_fmt yuv420p \
      -c:v libx264 \
      -qp 0 \
      -preset ultrafast \
      $@
  )
}

# Reimplementation of an xterm tool
resize() {
  printf '\033[18t'

  local width
  local height
  local state
  local char

  state=0
  while read -r -s -k 1 -t 1 char; do
    case "$state,$char" in
      "0,;")
        # End of CSI
        state=1
        ;;
      "1,;")
        # End of height
        stty rows $height
        state=2
        ;;
      "1,"*)
        height="$height$char"
        ;;
      "2,t")
        # End of width
        stty columns $width
        state=3
        ;;
      "2,"*)
        width="$width$char"
        ;;
    esac
    (( $state == 3 )) && break
  done
  # tmux <= 1.9.1 is buggy and doesn't end its answer with 't'
  (( $state == 2 )) && stty columns $width
}

# Simple calculator
function c() {
  echo $(($@))
}
alias c='noglob c'

# Currency conversion (with Google)
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
  (( $#currencies > 1 )) || currencies=($currencies chf eur usd)
  local from=${currencies[1]}
  for amount in $amounts; do
    for to in $currencies; do
      [[ ${to:u} != ${from:u} ]] || continue
      #echo "Convert $amount ${from:u} to ${to:u}"
      curl -s "http://www.google.com/finance/converter?a=$amount&from=$from&to=$to" | \
          sed '/res/!d;s/<[^>]*>//g'
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
    local curl="curl -s -$v --max-time 1"
    echo IPv$v $(false || \
        $=curl icanhazip.com || \
        $=curl ifconfig.co || \
        $=curl ip.appspot.com || \
        $=curl eth0.me || \
        $=curl ipecho.net/plain ||
        dig -$v +short myip.opendns.com @resolver1.opendns.com || \
        echo "unknown")
  done 2> /dev/null
}

# Display a man page
function wman() {
    case $DISPLAY in
        "") www-browser "https://manpages.debian.org/jump?q=$1" ;;
        *) x-www-browser "https://manpages.debian.org/jump?q=$1" ;;
    esac
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

    printf "\nGrayscale ramp:\n"
    for bg in {232..255}; do
      printf "\e[48;5;%dm  " bg
    done
    printf "\e[0m\n"

    # See: https://gist.github.com/XVilka/8346728
    printf "\nTrue colors:\n"
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
