# -*- sh -*-

# Alter window title
_vbe_title () {
    [ -t 1 ] || return
    emulate -L zsh
    local title
    title=${1//[^[:alnum:]\/>< ._~:=?@-]/ }
    shorttitle=${2:-$1}
    case $TERM in
	screen*)
	    print -n "\ek$shorttitle\e\\"
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
    local t tt
    local -a cmd
    cmd=(${(z)1})
    case $cmd[1] in
        fg)
            case $#cmd in
                1)
                    t=${jobtexts[${(k)jobstates[(R)*+*]}]}
                    ;;
                *)
                    t=${jobtexts[${cmd[2]#%}]}
                    ;;
            esac
            ;;
        %*)
	    t=${jobtexts[${cmd[1]#%}]}
	    ;;
	*=*)
	    shift cmd
	    ;&
	exec|sudo)
	    shift cmd
	    ;&
	*)
	    t=$cmd[*]
            tt=$cmd[1]:t
	    ;;
    esac
    _vbe_title "${SSH_TTY+${(%):-%M} }\> $t" "${SSH_TTY+${(%):-%M} }\> ${tt:-${t%% *}}"
}
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook preexec _title_preexec
else
    preexec () {
	_title_preexec
    }
fi
