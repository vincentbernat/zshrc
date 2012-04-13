# -*- sh -*-

# Grab some hosts from LDAP
if [[ $HOSTNAME == *.fti.net ]] && [[ -n $SSH_AUTH_SOCK ]]; then
    zmodload zsh/stat
    zmodload zsh/datetime
    if [[ ! -s $ZSH/local/hosts.hebex ]] || \
	[[ $(($EPOCHSECONDS - $(stat +mtime $ZSH/local/hosts.hebex))) -gt 86400 ]]; then
	echo -n "Rebuilding host cache... "
	ssh ldap01.infra.b2.p.fti.net "slapcat -s ou=hosts,dc=fti,dc=net | grep ^dn:" | \
	    sed -n 's/^dn: cn=\([^,]*\),.*/\1/p' | \
	    grep -E '\.(net|infra)\.'> $ZSH/local/hosts.hebex
	echo "done."
    fi
fi

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
