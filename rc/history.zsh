# -*- sh -*-

setopt extended_history	        # save timestamps
setopt share_history            # share history accross zsh sessions
setopt hist_ignore_all_dups	# ignores duplicates
setopt hist_ignore_space        # don't store commands starting with a space

HISTFILE=
() {
    local histfile
    for histfile in (
        ~/.zsh_history
        ~/.zsh/run/u/$HOST-$UID/history
        $ZSH/run/u/$HOST-$UID/history
    ); do
        if [[ -z HISTFILE ]]; then
            HISTFILE=$histfile
            continue
        fi
        if [[ $histfile -ef $HISTFILE ]]; then
            continue
        fi
        if [[ -O $HISTFILE ]] && [[ -O $histfile ]]; then
            if [[ $histfile -ot $HISTFILE ]]; then
                fc -R $histfile
                rm -f $histfile
                ln -s $HISTFILE $histfile
                continue
            fi
        fi
        HISTFILE=$histfile
    done
}

HISTSIZE=30000
SAVEHIST=30000

# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward
