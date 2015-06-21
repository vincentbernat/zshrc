# -*- sh -*-

setopt extended_history	        # save timestamps
setopt share_history            # share history accross zsh sessions
setopt hist_ignore_all_dups	# ignores duplicates

[[ -d $ZSH/run/history ]] || {
    mkdir -p $ZSH/run/history
    chmod 1777 $ZSH/run/history
}

if [[ -f $ZSH/run/history-${(%):-%m}-$UID ]] && [[ ! -f $ZSH/run/history/${(%):-%m}-$UID ]]; then
    mv $ZSH/run/history-${(%):-%m}-$UID $ZSH/run/history/${(%):-%m}-$UID
fi

HISTFILE=$ZSH/run/history/${(%):-%m}-$UID
HISTSIZE=20000
SAVEHIST=20000


# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward
