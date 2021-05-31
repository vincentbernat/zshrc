# -*- sh -*-

# Alter window title
_vbe_title () {
    [ -t 1 ] || return
    emulate -L zsh
    # In tmux.conf:
    #  set -g  set-titles on
    #  set -g  set-titles-string "#T"
    print -n "\e]0;$1\a"
}
if [[ ! -x $ZSH/run/u/$HOST-$UID/title ]] || \
       (( $(zstat +mtime $ZSH/run/u/$HOST-$UID/title) < $(zstat +mtime $0) )); then
    cat <<EOF > $ZSH/run/u/$HOST-$UID/title
#!/bin/zsh
$(which _vbe_title)
_vbe_title "\$@"
EOF
    chmod +x $ZSH/run/u/$HOST-$UID/title
fi

# Current running program as title
_vbe_title_preexec () {
    emulate -L zsh
    setopt extended_glob
    local title
    local -a cmd
    cmd=(${(z)1})
    while [[ -z $title ]]; do
        case $cmd[1] in
	    *=*|exec|sudo|noglob|\()
	        shift cmd
	        ;;
            fg)
                case $#cmd in
                    1)
                        cmd=(${(z)jobtexts[${(k)jobstates[(R)*+*]}]})
                        ;;
                    *)
                        cmd=(${(z)jobtexts[${cmd[2]#%}]})
                        ;;
                esac
                ;;
            %*)
	        cmd=(${(z)jobtexts[${cmd[1]#%}]})
	        ;;
	    *)
                case $cmd[1] in
                    less|more|v|e|vi|vim|emacs)
                        # Display filename
                        title=${${${(R)cmd:#-*}[2]}:t}
                        ;;
                    *)
                        title=$cmd[1]:t
	                ;;
                esac
                ;;
        esac
    done
    _vbe_title "${SSH_TTY+${(%):-%M} }${PRCH[running]}${title}"
}
add-zsh-hook preexec _vbe_title_preexec
