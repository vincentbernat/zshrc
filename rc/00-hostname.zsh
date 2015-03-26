# -*- sh -*-

__() {
    # Export HOSTNAME variable (fully qualified hostname)
    local -a hostnames
    local host
    hostnames=($(hostname -f)
	$(hostname)
	$(</etc/hostname)
	$HOST)
    [[ -r /etc/mailname ]] && hostnames=($hostnames
	$HOST.$(</etc/mailname))
    for host ($hostnames); do
	HOSTNAME=${host%%.}
	[[ $HOSTNAME == *.* ]] && break
    done
    export HOSTNAME

    # We put a short name in HOST. However, we may extend it by adding
    # some additional information, like a site indicator.
    HOST=${HOSTNAME%%.*}
    local remain=${HOSTNAME#*.}
    [[ $remain == *.*.* ]] && {
        local next=${remain%%.*}
        (( ${#next} >= 2 && ${#next} <= 4 )) && HOST=$HOST.$next
    }
} && __ 2> /dev/null
