# -*- sh -*-

# Some generic aliases
alias df='df -h'
alias du='du -h'
alias rm='rm -i'
alias ll='ls -l'
alias ip6='ip -6'

# smv like scp
alias smv='rsync -P --remove-source-files'
compdef _ssh smv=scp

# Less generic aliases
alias susu='sudo env HISTFILE=$HISTFILE-root ZDOTDIR=${ZDOTDIR:-$HOME} ZSH=$ZSH DISPLAY=$DISPLAY SSH_AUTH_SOCK=$SSH_AUTH_SOCK zsh -i -l'

# Global aliases (expanded even when not in a command position)
alias -g ...='../..'

# Aliases as a function
evince() { command evince ${*:-*.(djvu|dvi|pdf)(om[1])} }
md() { command mkdir -p $1 && cd $1 }

# JSON pretty-printing
json() {
  python -u -c '#!/usr/bin/env python

# Pretty-print files containing JSON lines. Reads from stdin when no
# argument is provided, otherwise pretty print each argument. This
# script should be invoked with "-u" to disable buffering. The shebang
# above is just for syntax highlighting to work correctly.

import sys
import json
try:
    import pygments
    from pygments.lexers import JavascriptLexer
    from pygments.formatters import TerminalFormatter
except ImportError:
    pygments = None


def display(f):
    while True:
        line = f.readline()
        if line == "":
            break
        try:
            j = json.loads(line)
            pretty = json.dumps(j, indent=2)
            if pygments and sys.stdout.isatty():
                pretty = pygments.highlight(pretty,
                                            JavascriptLexer(),
                                            TerminalFormatter())
            sys.stdout.write(pretty.strip() + "\n")
        except:
            sys.stdout.write(line)

if len(sys.argv) == 1:
    files = [sys.stdin]
else:
    files = sys.argv[1:]

for f in files:
    if type(f) != file:
        with file(f) as f:
            display(f)
    else:
        display(f)
' "$@"
}

# Other pretty-printing functions
if (( $+commands[pygmentize] )); then
  xml() {
    cat "$@" | xmllint --format - | pygmentize -l xml
  }

  pretty() {
    local formatter
    if (( ${terminfo[colors]:-0} >= 256 )); then
      formatter=console256
    else
      formatter=terminal
    fi

    local lexer
    lexer=$(pygmentize -N "${1%.gz}")

    local -a args
    args=(-P style=monokai -f $formatter)
    case $lexer in
      text)
        args=(-g $args)
        ;;
      *)
        args=(-l $lexer)
        ;;
    esac

    zcat -f "$@" | pygmentize $args | less -RFX
  }

  alias v=pretty
else
  xml() {
    cat "$@" | xmllint --format -
  }

  alias v=zless -FX
fi

# Record a video
screenrecord() {
  (
    eval $(xdotool selectwindow getwindowgeometry --shell) &&
    command ffmpeg -f x11grab \
      -draw_mouse 0 \
      -r 25 \
      -s ${WIDTH}x${HEIGHT} \
      -i ${DISPLAY}.${SCREEN:-0}+${X:-0},${Y:-0} \
      -dcodec copy \
      -pix_fmt yuv420p \
      -c:v libx264 \
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
    if [[ ${@[i]} = <-> ]]; then
      amounts=($amounts ${@[i]})
    else
      currencies=($currencies ${@[i]})
    fi
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
