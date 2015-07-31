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
            if _vbe_autoload colors; then
                colors
            else
                # Minimal version with what we need
                local -A color
                color=(none 00
                       fg-black 30 bg-black 40
                       fg-red 31 bg-red 41
                       fg-green 32 bg-green 42
                       fg-yellow 33 bg-yellow 43
                       fg-blue 34 bg-blue 44
                       fg-magenta 35 bg-magenta 45
                       fg-cyan 36 bg-cyan 46
                       fg-white 37 bg-white 47
                       fg-default 39 bg-default 49)
                local lc=$'\e[' rc=m
                local k
                typeset -AHg fg bg
                for k in ${(k)color[(I)fg-*]}; do
                    fg[${k#fg-}]="$lc${color[$k]}$rc"
                done
                for k in ${(k)color[(I)bg-*]}; do
                    bg[${k#bg-}]="$lc${color[$k]}$rc"
                done
                typeset -Hg reset_color
                reset_color="$lc${color[none]}$rc"
            fi
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
