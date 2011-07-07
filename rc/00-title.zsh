# -*- sh -*-

# Alter window title
function title {
    [ -t 1 ] || return
    if [[ "$TERM" == screen* ]]; then
	print -Pn "\ek$@:q\e\\"
	print -Pn "\e]2;$@:q\a"
    elif [[ $TERM == rxvt* ]] || [[ $TERM == xterm* ]]; then
	print -Pn "\e]2;$@:q\a"
    fi
}

# Current running program as title
function preexec {
    setopt extended_glob
    local CMD=${1[(wr)^(*=*|sudo|-*),-1]}
    title $HOST … $CMD
}
