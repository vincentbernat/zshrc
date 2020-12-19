# -*- sh -*-

autoload compinit && {
    autoload -U complist
    compinit -i -d $ZSH/run/u/$HOST-$UID/zcompdump
}

setopt auto_menu
setopt auto_remove_slash
setopt complete_in_word
setopt always_to_end
setopt glob_complete
unsetopt list_beep

zstyle ':completion:*' completer _expand_alias _complete _match _approximate
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:processes' command "ps -eo pid,user,comm,cmd -w -w"
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH/run/u/$HOST-$UID/cache/
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX + $#SUFFIX) / 3 )) )'
zstyle ':completion:history-words:*' remove-all-dups true

zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
zstyle ':completion:*:*:git-fetch:argument-rest:' tag-order '!remote-repositories'
zstyle ':completion:*:*:git-pull:argument-1:' tag-order '!remote-repositories'
zstyle ':completion:*:(ssh|scp|sftp|rsync):*:users' users root "$USERNAME" vincent blade cumulus

# Host completion
_custom_hosts() {
    # Complete ~/.zsh/local/hosts.*
    local host
    for host in $ZSH/local/hosts.*(N-.); do
	_wanted hosts expl "remote host name" compadd "$@" $(<$host)
    done
}
zstyle -e ':completion:*' hosts '_custom_hosts "$@"'

# Don't use known_hosts_file (too slow)
zstyle ":completion:*:hosts" known-hosts-files ''

# In menu, select items with +
zmodload -i zsh/complist
bindkey -M menuselect "+" accept-and-menu-complete
