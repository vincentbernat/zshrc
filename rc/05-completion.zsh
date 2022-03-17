# -*- sh -*-

autoload -Uz compinit complist
() {
    emulate -L zsh
    setopt extendedglob
    if [[ -n $1(#qN.mh+24) ]]; then
        zsh-defer compinit -i -d $1
    else
        zsh-defer compinit -C -d $1
    fi
} $ZSH/run/u/$HOST-$UID/zcompdump

setopt auto_menu
setopt auto_remove_slash
setopt complete_in_word
setopt always_to_end
setopt glob_complete
unsetopt list_beep

# To find the current context: "Ctrl-x h" instead of "Tab".
# To debug more: "Ctrl-x ?".

zstyle ':completion:*' completer _expand_alias _complete _match _approximate
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' group-name ''
zstyle ':completion:*' insert-unambiguous
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:match:*' original only
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH/run/u/$HOST-$UID/cache/
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX + $#SUFFIX) / 3 )) numeric )'
zstyle ':completion:history-words:*' remove-all-dups true

zstyle ':completion:*:*:-command-:*:*' ignored-patterns 'cowbuilder-*'
zstyle ':completion:*:processes' command "ps -eo pid,user,comm,cmd -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
zstyle ':completion:*:*:git-fetch:argument-rest:' tag-order '!remote-repositories'
zstyle ':completion:*:*:git-pull:argument-1:' tag-order '!remote-repositories'
zstyle ':completion:*:(ssh|scp|sftp|rsync):*:users' users root "$USERNAME" vincent blade cumulus

# Host completion
_vbe_custom_hosts() {
    # Complete ~/.zsh/local/hosts.*
    local host
    for host in $ZSH/local/hosts.*(N-.); do
	_wanted hosts expl "remote host name" compadd "$@" ${(M)$(<$host):#${PREFIX}*}
    done
}
zstyle -e ':completion:*' hosts '_vbe_custom_hosts "$@"'

# Don't use known_hosts_file (too slow)
zstyle ":completion:*:hosts" known-hosts-files ''

# In menu, select items with +
zmodload -i zsh/complist
bindkey -M menuselect "+" accept-and-menu-complete

# TODO: try fzf
# https://github.com/Aloxaf/fzf-tab
# https://github.com/lincheney/fzf-tab-completion
