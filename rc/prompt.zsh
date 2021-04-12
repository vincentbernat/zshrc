# -*- sh -*-

# _vbe_prompt_compact: whetever to use compact prompt
# _vbe_cmd_elapsed: elapsed time to be displayed in prompt
# _vbe_cmd_timestamp: timestamp to compute elapsed time for a command

_vbe_prompt_precmd () {
    _vbe_title "${SSH_TTY+${(%):-%M}:}${(%):-%50<..<%~}" "${SSH_TTY+${(%):-%M}:}${(%):-%20<..<%~}"
    local now=$EPOCHSECONDS
    _vbe_cmd_elapsed=$(($now - ${_vbe_cmd_timestamp:-$now}))
    unset _vbe_prompt_compact
    unset _vbe_cmd_timestamp
}
_vbe_prompt_preexec () {
    _vbe_cmd_timestamp=${_vbe_cmd_timestamp:-$EPOCHSECONDS}
}
add-zsh-hook precmd _vbe_prompt_precmd
add-zsh-hook preexec _vbe_prompt_preexec

# Ensure prompt is redrawn before executing a command
_vbe_reset-prompt-and-accept-line () {
    _vbe_prompt_compact=1
    zle reset-prompt
    zle .accept-line            # builtin
}
zle -N accept-line _vbe_reset-prompt-and-accept-line
_vbe_zle-isearch-exit () {
    [[ $KEYS != $'\r' ]] && return
    _vbe_prompt_compact=1
    zle reset-prompt
}
zle -N zle-isearch-exit _vbe_zle-isearch-exit
_vbe_reset-prompt-and-exit () {
    _vbe_prompt_compact=1
    zle reset-prompt
    exit
}
setopt ignoreeof
zle -N _vbe_reset-prompt-and-exit
bindkey '^D' _vbe_reset-prompt-and-exit
TRAPINT() {
    zle && [[ $#zsh_eval_context == 1 ]] && {
        _vbe_prompt_compact=1
        zle reset-prompt
    }
    return $((128+$1))
}

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
    print -n "${(pj::)result[1,2]}"
}

# Segment handling
_vbe_prompt_segment() {
  local b f
  [[ -n $1 ]] && b="%K{$1}" || b="%k"
  [[ -n $2 ]] && f="%F{$2}" || f="%f"
  [[ -n $3 ]] || return
  if [[ -n $CURRENT_BG && $1 != $CURRENT_BG ]]; then
      print -n " %b$b%F{$CURRENT_BG}${PRCH[end]}$f "
  elif [[ $1 == $CURRENT_BG ]]; then
      print -n " %b$b$f${PRCH[sep]} "
  else
      print -n "%b$b$f "
  fi
  CURRENT_BG=$1
  print -n ${3# *}
}
_vbe_prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n " %b%k%F{$CURRENT_BG}${PRCH[end]}"
  fi
  print -n "%b%k%f"
  unset CURRENT_BG
}

_vbe_prompt () {
    local retval=$?

    # When old command, just time + prompt sign
    if (( $_vbe_prompt_compact )); then
        _vbe_prompt_segment cyan default "%D{%H:%M}"
        [[ $SSH_TTY ]] && \
            _vbe_prompt_segment black magenta "%B%M%b"
        if (( $retval )); then
            _vbe_prompt_segment red default ${PRCH[reta]}
        else
            _vbe_prompt_segment green cyan ${PRCH[ok]}
        fi
        _vbe_prompt_end
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
        %B%n%b%F{cyan}${${(%):-%n}:+@}%B%K{black}%F{$f2}%M

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

    # Additional info
    _vbe_add_prompt

    # Time elapsed
    if (( $_vbe_cmd_elapsed >= 5 )); then
        _vbe_prompt_segment white black \
                            "${PRCH[elapsed]}$(_vbe_human_time $_vbe_cmd_elapsed)"
    fi

    # Error code
    if (( $retval )); then
        _vbe_prompt_segment red default %B${PRCH[retb]}$retval${PRCH[reta]}
    else
        _vbe_prompt_segment green cyan %B${PRCH[ok]}
    fi

    _vbe_prompt_end
}
_vbe_setprompt () {
    setopt prompt_subst
    PS1='$(_vbe_prompt) '
    PS2="$(_vbe_prompt_segment cyan default " "; _vbe_prompt_end) "
    PS3="$(_vbe_prompt_segment cyan default "?"; _vbe_prompt_end) "
    PS4="$(_vbe_prompt_segment white black "%N"; _vbe_prompt_segment blue default "%i"; _vbe_prompt_end) "
    PROMPT_EOL_MARK="%B${PRCH[eol]}%b"
    unset RPS1
    unset RPS2
}

# Collect additional information from functions matching _vbe_add_prompt_*
_vbe_add_prompt () {
    for f in ${(M)${(k)functions}:#_vbe_add_prompt_*}; do
	$f
    done
}

# Below are "current environment" indicator
_vbe_prompt_env () {
    local kind=$1
    local name=${(e)${2}}
    [[ -z $name ]] || {
        _vbe_prompt_segment blue black $kind
        _vbe_prompt_segment blue black $name
    }
}

[[ -z $LXC_CHROOT_NAME ]] || {
    _vbe_add_prompt_lxc () {
        _vbe_prompt_env 'lxc' '${LXC_CHROOT_NAME}'
    }
}
[[ -z $DOCKER_CHROOT_NAME ]] || {
    _vbe_add_prompt_docker () {
        _vbe_prompt_env "$PRCH[docker]" '${DOCKER_CHROOT_NAME##*/}'
    }
}

# Include schroot name in prompt if available
[[ ! -f /etc/debian_chroot ]] || [[ -n $LXC_CHROOT_NAME ]] || \
    SCHROOT_CHROOT_NAME=$(</etc/debian_chroot)
[[ -z $SCHROOT_CHROOT_NAME ]] || {
    _vbe_add_prompt_schroot () {
        _vbe_prompt_env 'sch' '${SCHROOT_CHROOT_NAME}'
    }
}

# In pbuilderrc, add:
#   export PBUILDERPID=$$
[[ -z $PBUILDERPID ]] || {
    _vbe_add_prompt_pbuilder () {
        _vbe_prompt_env 'pb' '${PBUILDERPID}'
    }
}

# In netns
(( $+commands[ip] )) && [[ -n "$(ip netns identify 2> /dev/null)" ]] && {
    _vbe_add_prompt_netns () {
        _vbe_prompt_env 'netns' "$(ip netns identify)"
    }
}

# In Cumulus VRF
(( $+commands[vrf] )) && case $(vrf identify) in
    default) ;;
    *)
        _vbe_add_prompt_netns () {
            _vbe_prompt_env 'vrf' "$(vrf identify)"
        }
        ;;
esac

# In nix-shell
[[ -n $IN_NIX_SHELL ]] && {
    _vbe_add_prompt_nixshell() {
        _vbe_prompt_env $PRCH[nix] ${${name#shell}:-${${IN_WHICH_NIX_SHELL:-${(j:+:)${${=${:-${buildInputs} ${nativeBuildInputs}}}#*-}:#glibc*}}:-${PRCH[ellipsis]}}}
    }
}

# In virtualenv
_vbe_add_prompt_virtualenv () {
    _vbe_prompt_env $PRCH[python] '${VIRTUAL_ENV##*/}'
}

_vbe_setprompt
