# -*- sh -*-

# Alter window title
_vbe_title () {
    [ -t 1 ] || return
    emulate -L zsh
    local title
    local shorttitle
    title=${1//[^[:alnum:]\/>< ._~:=?@-]/ }
    shorttitle=${2:-$1}
    print -n "\e]1;$title\a"
    print -n "\e]2;$shorttitle\a"
}
[ -x $ZSH/run/u/$HOST-$UID/title ] || {
    cat <<EOF > $ZSH/run/u/$HOST-$UID/title
#!/bin/zsh
$(which _vbe_title)
_vbe_title "\$@"
EOF
    chmod +x $ZSH/run/u/$HOST-$UID/title
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
	*=*|exec|sudo|\()
	    (( ${#cmd} > 1 )) && shift cmd
	    ;&
	*)
            case $cmd[1] in
                less|more|v|e|vi|vim|emacs|clogin)
                    # Display filename
                    t=$cmd[*]
                    tt=${${${(R)cmd:#-*}[2]}:t}
                    ;;
                *)
	            t=$cmd[*]
                    tt=$cmd[1]:t
	            ;;
            esac
            ;;
    esac
    _vbe_title "${SSH_TTY+${(%):-%M} }\> $t" "${SSH_TTY+${(%):-%M} }${PRCH[running]}${tt:-${t%% *}}"
}
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook preexec _title_preexec
else
    preexec () {
	_title_preexec
    }
fi
