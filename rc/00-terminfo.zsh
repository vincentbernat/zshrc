# -*- sh -*-

[[ $ZSH/rxvt-unicode.terminfo -nt $ZSH/rxvt-unicode.terminfo ]] && \
    TERMINFO=~/.terminfo tic $ZSH/rxvt-unicode.terminfo
