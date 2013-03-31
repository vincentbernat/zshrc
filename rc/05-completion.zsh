# -*- sh -*-

autoload -U zutil
autoload -U compinit
autoload -U complist
compinit -i -d $ZSH/run/zcompdump-$HOST-$UID

setopt auto_menu
setopt auto_remove_slash
setopt complete_in_word
setopt always_to_end
setopt glob_complete
setopt complete_aliases
unsetopt list_beep

zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:*:*:processes' command "ps -eo pid,user,comm -w -w"
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH/run/cache/
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Host completion
_custom_hosts() {
    # Complete ~/.zsh/local/hosts.*
    local host
    for host in $ZSH/local/hosts.*(N-.); do
	_wanted hosts expl host compadd "$@" $(<$host)
    done

    # And /etc/hosts
    _wanted hosts expl host \
	compadd "$@" ${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}

    # Now, try LDAP
    [[ -z $LDAPHOST ]] || {
	_wanted hosts expl host \
	    compadd "$@" ${$(ldapsearch -h $LDAPHOST \
	    -b "ou=hosts,dc=fti,dc=net" -LLL -s sub -z 100 \
	    -x "cn=${words[CURRENT]}*" cn 2> /dev/null)%* }
    }
}

zstyle -e ':completion:*' hosts _custom_hosts

# In menu, select items with +
zmodload -i zsh/complist
bindkey -M menuselect "+" accept-and-menu-complete

# Display dots when completion is in progress
expand-or-complete-with-dots() {
    echo -n "\e[31m...\e[0m"
    zle expand-or-complete
    zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots

compdef pumount=umount
