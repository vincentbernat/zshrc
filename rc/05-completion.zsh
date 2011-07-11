# -*- sh -*-

autoload -U zutil
autoload -U compinit
autoload -U complist
compinit -i -d $ZSH/run/zcompdump-$HOST-$UID

setopt auto_menu
setopt complete_in_word
setopt always_to_end

zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -eo pid,user,comm -w -w"
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH/run/cache/
zstyle ':completion:*:descriptions' format '%B%d%b'

zstyle -e ':completion:*' hosts 'reply=(
        # Take hosts from /etc/hosts
	${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}
	# And from local/hosts.*
	$(cat $ZSH/local/hosts.*(|2)(N) /dev/null)
    )'
