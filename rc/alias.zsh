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
alias susu='sudo env HISTFILE=$HISTFILE-root HOME=$HOME DISPLAY=$DISPLAY SSH_AUTH_SOCK=$SSH_AUTH_SOCK zsh -i -l'

# Global aliases (expanded even when not in a command position)
alias -g ...='../..'

# Aliases as a function
evince() { command evince ${*:-*.(djvu|dvi|pdf)(om[1])} }
md() { command mkdir -p $1 && cd $1 }

if (( $+commands[pygmentize] )); then
  json() {
    cat "$@" | python -mjson.tool | pygmentize -l javascript
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
    cat "$@" | python -mjson.tool
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
