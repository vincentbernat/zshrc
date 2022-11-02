# -*- sh -*-

(( $+commands[direnv] )) && {
    _direnv_hook() {
        trap -- '' SIGINT;
        eval "$(direnv export zsh)";
        trap - SIGINT;
    }
    chpwd_functions=( _direnv_hook ${chpwd_functions[@]} )

    _vbe_add_prompt_direnv () {
        [[ $DIRENV_STATUS == "allowed" ]] && _vbe_prompt_env $PRCH[envrc] ${DIRENV_DIR:t}
    }

    export DIRENV_LOG_FORMAT=""
}
