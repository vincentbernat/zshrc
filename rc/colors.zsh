# -*- sh -*-

(( ${terminfo[colors]:-0} >= 8 )) && {
    # ls colors
    export LSCOLORS="Gxfxcxdxbxegedabagacad"
    ls --color -d . &>/dev/null && alias ls='ls --color=tty' || {
        ls -G &> /dev/null && alias ls='ls -G'
    }

    alias grep='grep --color=auto'
}

# From: http://tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html
colortest() {
    local T='gYw'   # The test text

    local fg
    local bg
    printf "\n%12s" ""
    for fg in {40..47}; do
	printf "%7sm" ${fg}
    done
    printf "\n"
    for fg in 0 1 $(for i in {30..37}; do echo $i 1\;$i; done); do
	printf " %5s \e[%s  %s  " ${fg}m ${fg}m ${T}
	for bg in {40..47}m; do
	    printf " \e[%s\e[%s  %s  \e[0m" ${fg}m ${bg} ${T}
	done
	printf "\n"
    done
    printf "\n"
}
