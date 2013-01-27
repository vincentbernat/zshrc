# -*- sh -*-

# Use /bin/sh when no terminal is present
[[ ${TERM:-dumb} != "dumb" ]] || exec /bin/sh
[ -t 1 ] || exec /bin/sh

# Execute tmux if available and if we have some configuration for it
(( $+commands[tmux] )) && \
    [[ $TERM != screen* && -f ~/.tmux.conf ]] && \
    exec tmux

ZSH=${ZDOTDIR:-$HOME}/.zsh
fpath=($ZSH/functions $ZSH/completions $fpath)

# Autoload add-zsh-hook if available
autoload -U is-at-least
{ autoload -U +X add-zsh-hook || unset -f add-zsh-hook } 2> /dev/null

__() {
    for config_file ($ZSH/rc/*.zsh) source $config_file
    for plugin ($plugins) source $ZSH/plugins/$plugin.plugin.zsh
} && __

_vbe_setprompt
