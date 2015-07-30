# -*- sh -*-

# Update terminfo
__() {
    local terminfo
    local termpath
    for terminfo in $ZSH/terminfo/*.terminfo(.N); do
	# We assume that the file is named appropriately for this to work
	termpath=~/.terminfo/${(@)${terminfo##*/}[1]}/${${terminfo##*/}%%.terminfo}
	if [[ ! -e $termpath ]] || [[ $terminfo -nt $termpath ]]; then
	    TERMINFO=~/.terminfo tic $terminfo
	fi
    done
} && __

# Update TERM if we have LC__ORIGINALTERM variable
# Also, try a sensible term where we have terminfo stuff
autoload -U colors zsh/terminfo zsh/termcap
__() {
    local term
    local colors

    case $COLORTERM,$TERM in
        vbeterm,xterm | xfce4-terminal,xterm )
            TERM=xterm-256color
            ;;
    esac

    for term in $LC__ORIGINALTERM $TERM ${TERM/-256color} xterm-256color xterm; do
        TERM=$term 2> /dev/null
        if (( ${terminfo[colors]:-0} >= 8 )) || \
            (zmodload zsh/termcap 2> /dev/null) && \
            (( ${termcap[Co]:-0} >= 8)); then
            _vbe_autoload colors && colors
            break
        fi
    done
    unset LC__ORIGINALTERM
    unset COLORTERM
    export TERM
} && __


typeset -gA PRCH
if _vbe_can_do_unicode; then
    PRCH=(
        sep "\uE0B1" end "\uE0B0"
        retb "" reta " ↵"
        circle "●" branch "\uE0A0"
        ok "✔" ellipsis "…"
        eol "⏎" running "↻"
    )
else
    PRCH=(
        sep "/" end ""
        retb "<" reta ">"
        circle "*" branch "±"
        ok ">" ellipsis ".."
        eol "~~" running "> "
    )
fi
