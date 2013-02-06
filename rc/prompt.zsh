# -*- sh -*-
# Mostly taken from:
#  - https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/jonathan.zsh-theme
#  - https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/agnoster.zsh-theme

_vbe_prompt_precmd () {
    _vbe_title ${SSH_TTY+${HOST}:}${(%):-%~}
}
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook precmd _vbe_prompt_precmd
else
    precmd () {
	_vbe_prompt_precmd
    }
fi

_vbe_can_do_unicode () {
    if is-at-least 4.3.4 && [[ -o multibyte ]] && (( ${#${:-↵}} == 1 )); then
        case $TERM in
            screen*) ;;
            xterm*) ;;
            rxvt*) ;;
            *) return 1 ;;
        esac
        return 0
    fi
    return 1
}

typeset -gA PRCH
if _vbe_can_do_unicode; then
    PRCH=(
        sep "\uE0B1" end "\uE0B0"
        retb "" reta " ↵"
        circle "●" branch "\uE0A0"
        ok "✔" ellipsis "…"
    )
else
    PRCH=(
        sep "/" end ""
        retb "<" reta ">"
        circle "*" branch "±"
        ok ">" ellipsis ".."
    )
fi
CURRENT_BG=NONE
_vbe_prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  [[ -n $3 ]] || return
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
      print -n " %b$bg%F{$CURRENT_BG}${PRCH[end]}$fg "
  elif [[ $1 == $CURRENT_BG ]]; then
      print -n " %b$bg$fg${PRCH[sep]} "
  else
      print -n "%b$bg$fg "
  fi
  CURRENT_BG=$1
  print -n $3
}
_vbe_prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n " %b%k%F{$CURRENT_BG}${PRCH[end]}"
  else
    print -n "%b%k"
  fi
  print -n "%f"
  CURRENT_BG=''
}

_vbe_prompt () {
    local retval=$?

    # user@host
    local fg=${(%):-%(!.red.${${SSH_TTY:+magenta}:-green})}
    _vbe_prompt_segment black $fg \
        %B%n%b%F{cyan}@%B%K{black}%F{$fg}%m

    # Directory
    local -a segs
    local len=$(($COLUMNS - ${#${(%):-%n@%m}} - 6 - ${#${${(%):-%~}//[^\/]/}} * 2))
    segs=(${(s./.)${(%):-%${len}<${PRCH[ellipsis]}<%~}})
    [[ ${#segs} == 0 ]] && segs=(/)
    for seg in ${segs[1,-2]}; do
        _vbe_prompt_segment cyan default $seg
    done
    _vbe_prompt_segment cyan default %B${segs[-1]}
    _vbe_prompt_end

    # New line
    print
    CURRENT_BG=NONE

    # Additional info
    _vbe_add_prompt
    # Error code
    (( $retval )) && \
        _vbe_prompt_segment red default %B${PRCH[retb]}'%?'${PRCH[reta]} || \
        _vbe_prompt_segment green white %B${PRCH[ok]}

    _vbe_prompt_end
}

# Collect additional information from functions matching _vbe_add_prompt_*
_vbe_add_prompt () {
    for f in ${(M)${(k)functions}:#_vbe_add_prompt_*}; do
	$f
    done
}
_vbe_prompt_ps2 () {
    for seg in ${${(s. .)${1}}[1,-2]}; do
        _vbe_prompt_segment cyan default $seg
    done
    _vbe_prompt_end
}
_vbe_strip_colors() {
    local a=$1
    local b=$a
    while (( 1 )); do
        a=${(S)${(S)a#%F{*}}#%K{*}}
        [[ $a != $b ]] || break
        b=$a
    done
    echo $a
}
_vbe_setprompt () {
    setopt prompt_subst
    PROMPT='$(_vbe_prompt) '
    PS2='$(_vbe_prompt_ps2 ${(%):-%_}) '
    if ! is-at-least 4.3.7; then
        PROMPT="\$(_vbe_strip_colors \"$PROMPT\")"
        PS2="\$(_vbe_strip_colors \"$PS2\")"
    fi
    unset RPROMPT
}
