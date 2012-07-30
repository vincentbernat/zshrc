# -*- sh -*-

# Alter window title
_vbe_title () {
    [ -t 1 ] || return
    emulate -L zsh
    local title
    title=${@//[^[:alnum:]\/>< ._~:=?@-]/ }
    case $TERM in
	screen*)
	    print -n "\ek$title\e\\"
	    print -n "\e]1;$title\a"
	    print -n "\e]2;$title\a"
	    ;;
	rxvt*|xterm*)
	    print -n "\e]1;$title\a"
	    print -n "\e]2;$title\a"
	    ;;
    esac
}

# Current running program as title
_title_preexec () {
    emulate -L zsh
    setopt extended_glob
    local CMD=${1[(wr)^(*=*|sudo|-*),-1]}
    _vbe_title ${SSH_TTY+$HOST }\> $CMD
}
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook preexec _title_preexec
else
    preexec () {
	_title_preexec
    }
fi
