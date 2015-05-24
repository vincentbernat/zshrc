# -*- sh -*-
# Mostly taken from:
#  - https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/jonathan.zsh-theme
#  - https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/agnoster.zsh-theme

zmodload zsh/datetime
_vbe_prompt_precmd () {
    _vbe_title "${SSH_TTY+${(%):-%M}:}${(%):-%50<..<%~}" "${SSH_TTY+${(%):-%M}:}${(%):-%20<..<%~}"
}
_vbe_prompt_preexec () {
    _vbe_cmd_timestamp=$EPOCHSECONDS
}
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook precmd _vbe_prompt_precmd
    add-zsh-hook preexec _vbe_prompt_preexec
else
    precmd () {
	_vbe_prompt_precmd
    }
fi

# Stolen from https://github.com/sindresorhus/pure/blob/master/pure.zsh
_vbe_human_time () {
    local tmp=$1
    local days=$(( tmp / 60 / 60 / 24 ))
    local hours=$(( tmp / 60 / 60 % 24 ))
    local minutes=$(( tmp / 60 % 60 ))
    local seconds=$(( tmp % 60 ))
    local -a result
    (( $days > 0 )) && result=( "${days}d" )
    (( $hours > 0 )) && result=( $result "${hours}h" )
    (( $minutes > 0 )) && result=( $result "${minutes}m" )
    result=( $result "${seconds}s" )
    print -n "${result[1,2]}"
}

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
        eol "⏎"
    )
else
    PRCH=(
        sep "/" end ""
        retb "<" reta ">"
        circle "*" branch "±"
        ok ">" ellipsis ".."
        eol "~~"
    )
fi
CURRENT_BG=NONE
_vbe_prompt_segment() {
  local b f
  [[ -n $1 ]] && b="$bg[$1]" || b="$bg[default]"
  [[ -n $2 ]] && f="$fg[$2]" || f="$fg[default]"
  [[ -n $3 ]] || return
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
      print -n " %{%b$b$fg[$CURRENT_BG]%}${PRCH[end]}%{$f%} "
  elif [[ $1 == $CURRENT_BG ]]; then
      print -n " %{%b$b$f%}${PRCH[sep]} "
  else
      print -n "%{%b$b$f%} "
  fi
  CURRENT_BG=$1
  print -n $3
}
_vbe_prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n " %{%b$fg[$CURRENT_BG]%}${PRCH[end]}"
  else
    print -n "%{%b%}"
  fi
  print -n "%{${reset_color}%}"
  CURRENT_BG=''
}

_vbe_prompt () {
    local retval=$?

    # user@host
    local f=${(%):-%(!.red.${${SSH_TTY:+magenta}:-green})}
    _vbe_prompt_segment black $f \
        %B%n%b%{${fg[cyan]}%}@%B%{${bg[black]}${fg[$f]}%}%M

    # Directory
    local -a segs
    local len=$(($COLUMNS - ${#${(%):-%n@%M}} - 7 - ${#${${(%):-%~}//[^\/]/}} * 2))
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

    # Time elapsed
    local now=$EPOCHSECONDS
    local elapsed=$(($now - ${_vbe_cmd_timestamp:-$now}))
    (($elapsed >= 5)) && \
        _vbe_prompt_segment white black "$(_vbe_human_time $elapsed)"

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
_vbe_setprompt () {
    setopt prompt_subst
    PROMPT='$(_vbe_prompt) '
    PS2='$(_vbe_prompt_ps2 ${(%):-%_}) '
    PROMPT_EOL_MARK='%B${PRCH[eol]}%b'
    unset RPROMPT
}
