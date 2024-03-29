# -*- sh -*-

(( $+commands[direnv] )) && {
    _vbe_direnv_hook() {
        trap -- '' SIGINT;
        eval "$(direnv export zsh)";
        trap - SIGINT;
    }
    _vbe_direnv_maybe_hook() {
        [[ $DIRENV_STATUS == "allowed" ]] || return
        _vbe_direnv_hook
    }
    add-zsh-hook chpwd _vbe_direnv_hook
    add-zsh-hook precmd _vbe_direnv_maybe_hook

    _vbe_add_prompt_direnv () {
        [[ $DIRENV_STATUS == "allowed" ]] && _vbe_prompt_env $PRCH[envrc] ${DIRENV_DIR:t}
    }

    export DIRENV_LOG_FORMAT=""
    _vbe_direnv_hook
}
