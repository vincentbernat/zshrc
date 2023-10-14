# -*- sh -*-

_vbe_title () {
    emulate -L zsh
    [ -t 1 ] || return

    # In tmux.conf:
    #  set -g  set-titles on
    #  set -g  set-titles-string "#T"
    print -n "\e]0;$1\a"
}

# Current running program as title
_vbe_title_preexec () {
    emulate -L zsh
    setopt extendedglob
    local title
    local -a cmd
    cmd=(${(z)1})
    while [[ -z $title && -n $cmd ]]; do
        case $cmd[1] in
            \=*)
                cmd=(${cmd[1]#=} $cmd[2,-1])
                ;;
            *=*|exec|sudo|env|noglob|\()
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
            less|more|v|e|vi|vim|emacs)
                # Display filename
                title=${${${(R)cmd:#-*}[2]}:t}
                [[ -z $title ]] && title=$cmd[1]
                ;;
            *)
                title=$cmd[1]:t
                ;;
        esac
    done
    [[ -n $title ]] && \
        _vbe_title "${SSH_TTY+${(%):-%M} }${PRCH[running]}${title}"
}
add-zsh-hook preexec _vbe_title_preexec
