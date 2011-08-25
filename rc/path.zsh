# -*- sh -*-

__() {
    local wanted
    local p
    wanted=(/usr/local/sbin /usr/sbin /sbin /usr/local/bin /usr/bin /bin /usr/lib/ccache ~/bin)
    for p in $wanted; do
	(( ${${path[(r)$p]}:+1} )) || {
	    [ -d $p ] && path=($p $path)
	}
    done
} && __
