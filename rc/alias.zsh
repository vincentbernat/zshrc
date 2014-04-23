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
alias susu='sudo env HISTFILE=$HISTFILE-root HOME=$HOME DISPLAY=$DISPLAY SSH_AUTH_SOCK=$SSH_AUTH_SOCK zsh'

# Global aliases (expanded even when not in a command position)
alias -g ...='../..'

# Aliases as a function
evince() { command evince ${*:-*.(djvu|dvi|pdf)(om[1])} }
md() { command mkdir -p $1 && cd $1 }

if (( $+commands[pygmentize] )); then
  json() {
    if (( $# > 0 )); then
      cat "$@" | python -mjson.tool | pygmentize -l javascript
    else
      python -mjson.tool | pygmentize -l javascript
    fi
  }

  pretty() {
    pygmentize -g "$@" | less -RFX
  }
else
  json() {
    if (( $# > 0 )); then
      cat "$@" | python -mjson.tool
    else
      python -mjson.tool
    fi
  }
fi

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
