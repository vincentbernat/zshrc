# -*- sh -*-

# ls colors
export LSCOLORS="Gxfxcxdxbxegedabagacad"
ls --color -d . &>/dev/null && alias ls='ls --color=tty' || alias ls='ls -G'

# grep colors
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'
