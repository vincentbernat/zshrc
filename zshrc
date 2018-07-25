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
fpath=($ZSH/functions $ZSH/completions $fpath)

[[ $ZSH_NAME == "zsh-static" ]] && [[ -d /usr/share/zsh-static ]] && {
    # Rewrite /usr/share/zsh to /usr/share/zsh-static
    fpath=(${fpath/\/usr\/share\/zsh\//\/usr\/share\/zsh-static\/})
}

# Autoload add-zsh-hook if available
autoload -U is-at-least
{ autoload -U +X add-zsh-hook || unset -f add-zsh-hook } 2> /dev/null

() {
    for config_file ($ZSH/rc/*.zsh) source $config_file
        [ ! -e $ZSH/env ] || . $ZSH/env
}

_vbe_setprompt
