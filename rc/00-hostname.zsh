# -*- sh -*-

# Export HOSTNAME variable
() {
    local -a hostnames
    local host
    hostnames=($(hostname -f)
	$(hostname)
	$(</etc/hostname)
	$HOST
	$HOST.$(</etc/mailname)
	$HOST)
    for host ($hostnames); do
	HOSTNAME=${host%%.}
	[[ $HOSTNAME == *.* ]] && break
    done
    export HOSTNAME
} 2> /dev/null
