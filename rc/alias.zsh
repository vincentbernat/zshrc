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
