# -*- sh -*-

setopt extended_history	        # save timestamps
setopt share_history            # share history accross zsh sessions
setopt hist_ignore_all_dups	# ignores duplicates
setopt hist_ignore_space        # don't store commands starting with a space

HISTFILE=$ZSH/run/u/$HOST-$UID/history
HISTSIZE=30000
SAVEHIST=30000

# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward
