# -*- sh -*-

# Execute tmux if available and if we have some configuration for it
[ -t 1 ] && (( $+commands[tmux] )) && \
      [[ -f ~/.tmux.conf && \
               $PPID != 1 && \
               $$ != 1 && \
               $TERM != dumb &&
               $TERM != linux && \
               $TERM != screen* && \
               -z $TMUX ]] && \
      exec tmux

ZSH=${ZSH:-${ZDOTDIR:-$HOME}/.zsh}

# fpath
fpath=(
    # Custom functions and completions
    $ZSH/functions $ZSH/completions
    # For nix-shell, add share/zsh for elements in PATH (for nix-shell)
    ${^${(M)path:#/nix/store/*}}/../share/zsh/site-functions(N/)
    # Add functions from our own profile (for home-manager)
    ~/.nix-profile/share/zsh/site-functions(N/)
    # Default fpath
    $fpath
)
[[ $ZSH_NAME == "zsh-static" ]] && [[ -d /usr/share/zsh-static ]] && {
    # Rewrite /usr/share/zsh to /usr/share/zsh-static
    fpath=(${fpath/\/usr\/share\/zsh\//\/usr\/share\/zsh-static\/})
}

[[ $TERM == "dumb" ]] && unsetopt zle && PS1='%(!.#.$) ' && return

() {
    local config_file
    for config_file ($ZSH/rc/*.zsh) source $config_file
}
