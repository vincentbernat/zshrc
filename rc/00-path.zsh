# -*- sh -*-

__() {
    local -a wanted savedpath
    local p
    wanted=(~/bin /usr/lib/ccache /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin)
    savedpath=($path)
    path=()
    for p in $wanted $savedpath; do
        p=${p:A}
	(( ${${path[(r)$p]}:+1} )) || {
	    [ -d $p ] && path=($path $p)
	}
    done
} && __
