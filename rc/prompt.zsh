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

typeset -gA PRCH
if is-at-least 4.3.4 && [[ -o multibyte ]]; then
    PRCH=(
        sep "\uE0B1" end "\uE0B0"
        retb "" reta " ↵"
        circle "●" branch "\uE0A0"
        ok "✓"
    )
else
    PRCH=(
        sep "/" end ""
        retb "<" reta ">"
        circle "*" branch "±"
        ok ">"
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
    _vbe_prompt_segment ${(%):-%(!.red.${${SSH_TTY:+magenta}:-blue})} black \
        %n%F{cyan}@%F{black}%m

    # Directory
    local -a segs
    segs=(${(s./.)${(%):-%~}})
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
    for f in ${(k)functions}; do
	[[ $f == _vbe_add_prompt_* ]] || continue
	$f
    done
}
_vbe_setprompt () {
    setopt prompt_subst
    PROMPT='$(_vbe_prompt) '
    PS2='$(_vbe_prompt_segment cyan default %_ ; _vbe_prompt_end)'
    unset RPROMPT
}
