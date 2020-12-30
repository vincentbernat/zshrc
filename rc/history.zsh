# -*- sh -*-

setopt extended_history	        # save timestamps
setopt share_history            # share history accross zsh sessions
setopt hist_ignore_all_dups	# ignores duplicates
setopt hist_ignore_space        # don't store commands starting with a space

case $HOSTNAME in
    *.blade-group.net)
        HISTFILE=~/.zsh_history
        if [[ -O $ZSH/run/u/$HOST-$UID/history ]]; then
            fc -R $ZSH/run/u/$HOST-$UID/history
            fc -A
            rm -f $ZSH/run/u/$HOST-$UID/history
        fi
        ;;
    *) HISTFILE=$ZSH/run/u/$HOST-$UID/history ;;
esac
HISTSIZE=30000
SAVEHIST=30000

# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward
