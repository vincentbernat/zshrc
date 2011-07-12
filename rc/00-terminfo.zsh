# -*- sh -*-

[[ $ZSH/rxvt-unicode.terminfo -nt $ZSH/rxvt-unicode.terminfo ]] && \
    TERMINFO=~/.terminfo tic $ZSH/rxvt-unicode.terminfo

autoload -U colors zsh/terminfo
[[ "$terminfo[colors]" -ge 8 ]] && colors
