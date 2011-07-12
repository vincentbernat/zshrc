# -*- sh -*-

[[ "$terminfo[colors]" -ge 8 ]] && {
    # ls colors
    export LSCOLORS="Gxfxcxdxbxegedabagacad"
    ls --color -d . &>/dev/null && alias ls='ls --color=tty' || alias ls='ls -G'

    # grep colors
    export GREP_OPTIONS='--color=auto'
    export GREP_COLOR='1;32'

    # less colors
    export LESS_TERMCAP_md=$fg_bold[green]
    export LESS_TERMCAP_us=$fg_no_bold[yellow]
    export LESS_TERMCAP_so=$bg[magenta]$fg_bold[white]
    export LESS_TERMCAP_me=$reset_color
    export LESS_TERMCAP_se=$reset_color
    export LESS_TERMCAP_ue=$reset_color
}
