# -*- sh -*-

# Alter window title
_vbe_title () {
    [ -t 1 ] || return
    if [[ "$TERM" == screen* ]]; then
	print -n "\ek$@:q\e\\"
	print -n "\e]2;$@:q\a"
    elif [[ $TERM == rxvt* ]] || [[ $TERM == xterm* ]]; then
	print -n "\e]2;$@:q\a"
    fi
}

# Current running program as title
_title_preexec () {
    setopt extended_glob
    local CMD=${1[(wr)^(*=*|sudo|-*),-1]}
    _vbe_title $HOST \> $CMD
}
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook preexec _title_preexec
else
    preexec () {
	_title_preexec
    }
fi
