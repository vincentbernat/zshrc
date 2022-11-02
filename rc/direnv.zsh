# -*- sh -*-

(( $+commands[direnv] )) && {
    _direnv_hook() {
        trap -- '' SIGINT;
        eval "$(direnv export zsh)";
        trap - SIGINT;
    }
    chpwd_functions=( _direnv_hook ${chpwd_functions[@]} )
}
