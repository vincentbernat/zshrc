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

if (( $+commands[pygmentize] )); then
  json() {
    if (( $# == 0 )); then
      while read line; do echo $line | python -mjson.tool | pygmentize -l javascript ; done
    else
      cat "$@" | python -mjson.tool | pygmentize -l javascript
    fi
  }
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
  json() {
    if (( $# == 0 )); then
      while read line; do echo $line | python -mjson.tool ; done
    else
      cat "$@" | python -mjson.tool
    fi
  }
  xml() {
    cat "$@" | xmllint --format -
  }

  alias v=zless -FX
fi

screenrecord() {
  (
    eval $(xdotool selectwindow getwindowgeometry --shell) &&
    command avconv -f x11grab \
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

# Lots of command examples (especially heroku) lead command docs with '$' which
# make it kind of annoying to copy/paste, especially when there's multiple
# commands to copy.
#
# This hacks around the problem by making a '$' command that simply runs
# whatever arguments are passed to it. So you can copy
#   '$ echo hello world'
# and it will run 'echo hello world'
function \$() {
  "$@"
}
