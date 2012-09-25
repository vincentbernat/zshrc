# -*- sh -*-

# Export HOSTNAME variable
__() {
    local -a hostnames
    local host
    hostnames=($(hostname -f)
	$(hostname)
	$(</etc/hostname)
	$HOST
	$HOST.$(</etc/mailname))
    for host ($hostnames); do
	HOSTNAME=${host%%.}
	[[ $HOSTNAME == *.* ]] && break
    done
    export HOSTNAME
} && __ 2> /dev/null
