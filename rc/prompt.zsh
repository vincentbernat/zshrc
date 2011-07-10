# -*- sh -*-
# Mostly taken from: https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/jonathan.zsh-theme

autoload add-zsh-hook

_vbe_prompt_precmd () {
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))

    ###
    # Truncate the path if it's too long.
    
    PR_FILLBAR=""
    PR_PWDLEN=""
    
    local promptsize=${#${(%):---(%n@%m)---()--}}
    local pwdsize=${#${(%):-%~}}
    
    if [[ "$promptsize + $pwdsize" -gt $TERMWIDTH ]]; then
	((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
	PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $pwdsize)))..${PR_HBAR}.)}"
    fi

    _vbe_title ${HOST}:${PWD}
}
add-zsh-hook precmd _vbe_prompt_precmd

autoload colors zsh/terminfo
if [[ "$terminfo[colors]" -ge 8 ]]; then
    colors
fi
for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
    eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
    eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
done
PR_NO_COLOUR="%{$terminfo[sgr0]%}"

###
# See if we can use extended characters to look nicer.
() {
    local -A altchar
    set -A altchar ${(s..)terminfo[acsc]}
    PR_SET_CHARSET="%{$terminfo[enacs]%}"
    PR_SHIFT_IN="%{$terminfo[smacs]%}"
    PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
    PR_HBAR=${altchar[q]:--}
    PR_ULCORNER=${altchar[l]:--}
    PR_LLCORNER=${altchar[m]:--}
    PR_LRCORNER=${altchar[j]:--}
    PR_URCORNER=${altchar[k]:--}
}
    
_vbe_setprompt () {
    setopt prompt_subst
    
    PROMPT='$PR_SET_CHARSET\
$PR_CYAN$PR_SHIFT_IN$PR_ULCORNER$PR_HBAR$PR_SHIFT_OUT$PR_GREY(\
%(!.$PR_RED%n.$PR_GREEN${SSH_TTY:+$PR_MAGENTA}%n)$PR_GREY@$PR_GREEN${SSH_TTY:+$PR_MAGENTA}%m\
$PR_GREY)$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_HBAR${(e)PR_FILLBAR}$PR_HBAR$PR_SHIFT_OUT$PR_GREY(\
$PR_GREEN${SSH_TTY:+$PR_MAGENTA}%$PR_PWDLEN<...<%~%<<\
$PR_GREY)$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_URCORNER$PR_SHIFT_OUT\

$PR_CYAN$PR_SHIFT_IN$PR_LLCORNER$PR_BLUE$PR_HBAR$PR_SHIFT_OUT(\
$PR_YELLOW%D{%H:%M}\
$PR_LIGHT_BLUE$PR_NO_COLOUR$PR_BLUE)$PR_CYAN$PR_SHIFT_IN$PR_HBAR\
$PR_NO_COLOUR${PR_SHIFT_OUT}'$(_vbe_add_prompt)'\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
%(!.${PR_RED}#.$)$PR_NO_COLOUR '

    # display exitcode on the right when >0
    if [[ -o multibyte ]]; then
	return_code="%(?..%{$PR_RED%}%? ↵ $PR_NO_COLOUR)"
    else
	return_code="%(?..%{$PR_RED%}<%?> $PR_NO_COLOUR)"
    fi
    RPROMPT=' $return_code$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_BLUE$PR_HBAR$PR_SHIFT_OUT\
($PR_YELLOW%D{%b%d}$PR_BLUE)$PR_SHIFT_IN$PR_HBAR$PR_CYAN$PR_LRCORNER$PR_SHIFT_OUT$PR_NO_COLOUR'

    PS2='$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_BLUE$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(\
$PR_LIGHT_GREEN%_$PR_BLUE)$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR '
}

# Collect additional information from functions matching _vbe_add_prompt_*
_vbe_add_prompt () {
    for f in ${(k)functions}; do
	[[ $f == _vbe_add_prompt_* ]] || continue
	$f
    done
}

[ -t 1 ] && print -Pn '\e]12;2\a'
