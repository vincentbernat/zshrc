# -*- sh -*-

setopt extended_history	        # save timestamps
setopt share_history            # share history accross zsh sessions
setopt hist_ignore_all_dups	# ignores duplicates
setopt hist_ignore_space        # don't store commands starting with a space

() {
    local domain=${(pj:.:)${(ps:.:)HOSTNAME}[-2,-1]}
    local hashed=${"$(print Ahyeigh4yo $domain | ${commands[sha256sum]:-$commands[sha256]} 2> /dev/null)"[1,16]}
    case $hashed in
        49e78cdf67755528)
            typeset -g HISTFILE=~/.zsh_history
            if [[ -O $ZSH/run/u/$HOST-$UID/history ]]; then
                fc -R $ZSH/run/u/$HOST-$UID/history
                fc -A
                rm -f $ZSH/run/u/$HOST-$UID/history
            fi
            ;;
        12e640a29535f352) typeset -g HISTFILE=~/.zhistory ;;
        *) typeset -g HISTFILE=$ZSH/run/u/$HOST-$UID/history ;;
    esac
}
HISTSIZE=30000
SAVEHIST=30000

# Ctrl-r search in the history with patterns
(( $+widgets[history-incremental-pattern-search-backward] )) &&	\
    bindkey '^r' history-incremental-pattern-search-backward
