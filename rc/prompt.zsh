# -*- sh -*-
# Mostly taken from:
#  - https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/jonathan.zsh-theme
#  - https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/agnoster.zsh-theme

_vbe_prompt_precmd () {
    _vbe_title "${SSH_TTY+${(%):-%M}:}${(%):-%50<..<%~}" "${SSH_TTY+${(%):-%M}:}${(%):-%20<..<%~}"
    local now=$EPOCHSECONDS
    _vbe_cmd_elapsed=$(($now - ${_vbe_cmd_timestamp:-$now}))
    unset _vbe_cmd_timestamp
}
_vbe_prompt_preexec () {
    _vbe_cmd_timestamp=${_vbe_cmd_timestamp:-$EPOCHSECONDS}
}
add-zsh-hook precmd _vbe_prompt_precmd
add-zsh-hook preexec _vbe_prompt_preexec

_vbe_reset-prompt-and-accept-line () {
    _vbe_cmd_elapsed=-1
    zle reset-prompt
    zle .accept-line            # builtin
}
zle -N accept-line _vbe_reset-prompt-and-accept-line
zle-isearch-exit () {
    [[ $KEYS != $'\r' ]] && return
    _vbe_cmd_elapsed=-1
    zle reset-prompt
}
zle -N zle-isearch-exit

# Stolen from https://github.com/sindresorhus/pure/blob/master/pure.zsh
_vbe_human_time () {
    local tmp=$1
    local days=$(( tmp / 60 / 60 / 24 ))
    local hours=$(( tmp / 60 / 60 % 24 ))
    local minutes=$(( tmp / 60 % 60 ))
    local seconds=$(( tmp % 60 ))
    local -a result
    (( $days    > 0 )) && result=( "${days}d" )
    (( $hours   > 0 )) && result=( $result "${hours}h" )
    (( $minutes > 0 )) && result=( $result "${minutes}m" )
    (( $seconds > 0 )) && result=( $result "${seconds}s" )
    print -n "${result[1,2]}"
}

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

    # When old command, just time + prompt sign
    if (($_vbe_cmd_elapsed < 0)); then
        print -n "%{${fg[yellow]}%}%T %{%B${fg[${(%):-%(!.red.green)}]}%}${PRCH[prompt]}%{${reset_color}%}"
        return
    fi

    print
    # user:
    #  - when root, red
    #  - when sudo in action, white
    #  - otherwise, green
    # host:
    #  - when remote: magenta
    #  - when local: same as user
    local f1=${(%):-%(!.red.${${SUDO_USER:+white}:-green})}
    local f2=${(%):-${${SSH_TTY:+magenta}:-$f1}}
    _vbe_prompt_segment black $f1 \
        %B%n%b%{${fg[cyan]}%}${${(%):-%n}:+@}%B%{${bg[black]}${fg[$f2]}%}%M

    # Directory
    local -a segs
    local remaining=$(($COLUMNS - ${#${(%):-%n@%M}} - 7))
    local pwd=${(%):-%~}
    # When splitting, we will loose the leading /, keep it if needed
    local leading=${pwd[1]}
    [[ $leading == / ]] || leading=
    segs=(${(s./.)pwd})
    # We try to shorten middle segments if needed (but not the first, not the last)
    case ${#segs} in
        0) _vbe_prompt_segment cyan default %B/ ;;
        1) _vbe_prompt_segment cyan default ${leading}%B${segs[1]} ;;
        *)
            local i=2
            local current
            while true; do
                current=${leading}${(j./.)${segs[1,-2]}}/%B${segs[-1]}
                (( i < ${#segs} )) || break
                (( ${#current} < remaining )) && break
                segs[i]=${segs[i][1]}
                ((i++))
            done
            _vbe_prompt_segment cyan default ${(%):-%${remaining}<${PRCH[ellipsis]}<$current}
            ;;
    esac
    _vbe_prompt_end

    # New line
    print
    CURRENT_BG=NONE

    # Additional info
    _vbe_add_prompt

    # Time elapsed
    if (($_vbe_cmd_elapsed >= 5)); then
        _vbe_prompt_segment white black "$(_vbe_human_time $_vbe_cmd_elapsed)"
    fi

    # Error code
    (( $retval )) && \
        _vbe_prompt_segment red default %B${PRCH[retb]}'%?'${PRCH[reta]} || \
        _vbe_prompt_segment green cyan %B${PRCH[ok]}

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
    PROMPT_EOL_MARK="%B${PRCH[eol]}%b"
    unset RPROMPT
    unset RPS1
}
