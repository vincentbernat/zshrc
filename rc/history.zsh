# -*- sh -*-

setopt extended_history	        # save timestamps
setopt share_history            # share history accross zsh sessions
setopt hist_ignore_all_dups	# ignores duplicates

HISTFILE=$ZSH/run/history-${(%):-%m}-$UID
HISTSIZE=20000
SAVEHIST=20000

# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward

# Remove old history files
rm -f $ZSH/run/history-*(NU.mw+10)
