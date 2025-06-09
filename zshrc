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
[[ -n "$TMUX" && -S "${TMUX%,*,*}" ]] || unset TMUX

case $SHELL in
   */zsh) ;;
   */zsh-static) ;;
   *) SHELL=${${0#-}:c:A}
esac

autoload -Uz is-at-least
autoload -Uz add-zsh-hook
autoload -Uz add-zle-hook-widget

is-at-least 5.0.2 ||
   echo "[!] Minimal version supported is 5.0.2 (got $ZSH_VERSION)"

[[ $ZSH_NAME == "zsh-static" ]] && is-at-least 5.4.1 && {
    # Don't tell us when modules are not available
    alias zmodload='zmodload -s'
}

zmodload -F zsh/stat b:zstat
zmodload zsh/datetime           # EPOCHSECONDS

() {
    local config_file
    for config_file ($ZSH/rc/*.zsh) source $config_file
}

:
