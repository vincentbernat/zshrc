# -*- sh -*-

# Alter window title
_vbe_title () {
    [ -t 1 ] || return
    emulate -L zsh
    local title
    local shorttitle
    title=${1//[^[:alnum:]\/>< ._~:=?@-]/ }
    shorttitle=${2:-$1}
    # In tmux.conf:
    #  set -g  set-titles on
    #  set -g  set-titles-string "#T"
    print -n "\e]1;$title\a"
    print -n "\e]2;$shorttitle\a"
}
if [[ ! -x $ZSH/run/u/$HOST-$UID/title ]] || \
       (( $EPOCHSECONDS - $(zstat +mtime $ZSH/run/u/$HOST-$UID/title) > 60*60*24 )); then
    cat <<EOF > $ZSH/run/u/$HOST-$UID/title
#!/bin/zsh
$(which _vbe_title)
_vbe_title "\$@"
EOF
    chmod +x $ZSH/run/u/$HOST-$UID/title
fi

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
add-zsh-hook preexec _title_preexec
