# -*- sh -*-
# Mostly taken from: https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/jonathan.zsh-theme

_vbe_prompt_precmd () {
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))

    ###
    # Truncate the path if it's too long.
    
    PR_PWDLEN=""
    
    local promptsize=${#${(%):---(%n@%m)---()--}}
    local pwdsize=${#${(%):-%~}}
    
    if [[ "$promptsize + $pwdsize" -gt $TERMWIDTH ]]; then
	((PR_PWDLEN=$TERMWIDTH - $promptsize))
    fi

    _vbe_title ${SSH_TTY+${HOST}:}${(%):-%~}
}
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook precmd _vbe_prompt_precmd
else
    precmd () {
	_vbe_prompt_precmd
    }
fi

for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
    eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
    eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
done
PR_NO_COLOUR="%{$terminfo[sgr0]%}"

###
# See if we can use extended characters to look nicer.
__() {
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
} && __
    
_vbe_setprompt () {
    setopt prompt_subst
    local return_code
    
    # display exitcode on the right when >0
    if is-at-least 4.3.4 && [[ -o multibyte ]]; then
	return_code="%(?..$PR_RED%? ↵ $PR_NO_COLOUR)"
    else
	return_code="%(?..$PR_RED<%?> $PR_NO_COLOUR)"
    fi

    PROMPT='$PR_SET_CHARSET\
$PR_CYAN$PR_SHIFT_IN$PR_ULCORNER$PR_HBAR$PR_SHIFT_OUT$PR_GREY(\
%(!.$PR_RED%n.$PR_GREEN${SSH_TTY:+$PR_MAGENTA}%n)$PR_GREY@$PR_GREEN${SSH_TTY:+$PR_MAGENTA}%m\
$PR_GREY)$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_HBAR$PR_SHIFT_OUT${PR_GREY}[\
$PR_GREEN${SSH_TTY:+$PR_MAGENTA}%$PR_PWDLEN<...<%~%<<\
${PR_GREY}]$PR_SHIFT_OUT\

$PR_CYAN$PR_SHIFT_IN$PR_LLCORNER$PR_CYAN$PR_HBAR$PR_SHIFT_OUT\
$PR_NO_COLOUR'$(_vbe_add_prompt)'\
%(!.${PR_RED}#.${PR_CYAN}$)$PR_NO_COLOUR '$return_code

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
	print -n '${PR_NO_COLOUR}'
    done
}
