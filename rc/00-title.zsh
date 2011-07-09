# -*- sh -*-

# Alter window title
function title {
    [ -t 1 ] || return
    if [[ "$TERM" == screen* ]]; then
	print -n "\ek$@:q\e\\"
	print -n "\e]2;$@:q\a"
    elif [[ $TERM == rxvt* ]] || [[ $TERM == xterm* ]]; then
	print -n "\e]2;$@:q\a"
    fi
}

# Current running program as title
function preexec {
    setopt extended_glob
    local CMD=${1[(wr)^(*=*|sudo|-*),-1]}
    title $HOST \> $CMD
}
