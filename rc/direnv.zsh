# -*- sh -*-

(( $+commands[direnv] )) && {
    _direnv_hook() {
        trap -- '' SIGINT;
        eval "$(direnv export zsh)";
        trap - SIGINT;
    }
    typeset -ag chpwd_functions;
    if [[ -z "${chpwd_functions[(r)_direnv_hook]+1}" ]]; then
        chpwd_functions=( _direnv_hook ${chpwd_functions[@]} )
    fi
}
