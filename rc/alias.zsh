# -*- sh -*-

# Some generic aliases
alias df='df -h'
alias du='du -h'
alias rm='rm -i'
alias ll='ls -l'

# Less generic aliases
alias susu='sudo env HISTFILE=$HISTFILE-root HOME="$HOME" zsh'
alias us='setxkbmap us "" compose:rwin ; xmodmap -e "keysym Pause = XF86ScreenSaver"'
alias fr='setxkbmap fr'

# Open anything (needs gvfs-open from `gvfs-bin` package)
(( $+commands[gvfs-open] )) && alias o='gvfs-open'
