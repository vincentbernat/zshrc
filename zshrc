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

[[ -o interactive ]] && \
   case $SHELL in
      */zsh) ;;
      */zsh-static) ;;
      *) SHELL=${${0#-}:c:A}
   esac

() {
    local config_file
    for config_file ($ZSH/rc/*.zsh) source $config_file
}

:
