# -*- sh -*-

setopt EXTENDED_HISTORY	
setopt SHARE_HISTORY # _all_ zsh sessions share the same history files
setopt HIST_IGNORE_ALL_DUPS	# ignores duplications

HISTFILE=$ZSH/run/history-$HOST-$UID
HISTSIZE=20000
SAVEHIST=20000

# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward
