# -*- sh -*-

# Telnet through HNM
telnet() {
    _vbe_title "$@"
    case "$1" in
	*.net.b?.p.fti.net|swbg*)
	    host=bgadm
	    ;;
	*.net.s?.p.fti.net)
	    host=soadm
	    ;;
	*.net.m?.p.fti.net)
	    host=mtadm
	    ;;
	*)
	    # Don't know how to handle, let's just use normal telnet
	    command telnet "$@"
	    return
	    ;;
    esac
    LANG=C LC_MESSAGES=C command ssh -t $host \
	telnet $1
}
