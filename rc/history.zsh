# -*- sh -*-

setopt extended_history		# save timestamps
setopt share_history			# share history accross zsh sessions
setopt hist_ignore_all_dups	# ignores duplicates
setopt hist_ignore_space		# don't store commands starting with a space

HISTFILE=$ZSHRUN/history
HISTSIZE=100000
SAVEHIST=100000

# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward
