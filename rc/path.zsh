# -*- sh -*-

__() {
    local wanted
    wanted=(/usr/local/sbin /usr/sbin /sbin /usr/local/bin /usr/bin /bin)
    for p in $wanted; do
	(( ${${path[(r)$p]}:+1} )) || \
	    path=($path $p)
    done
} && __
