# -*- sh -*-

__() {
    # Export HOSTNAME variable (fully qualified hostname)
    local -a hostnames
    local host
    hostnames=($(hostname -f)
	$(hostname)
	$(</etc/hostname)
	$HOST)
    [[ -r /etc/mailname ]] && \
        hostnames=($hostnames $HOST.$(</etc/mailname))
    for host ($hostnames); do
	HOSTNAME=${host%%.}
	[[ $HOSTNAME == *.* ]] && break
    done
    export HOSTNAME

    # We put a short name in HOST. However, we may extend it by adding
    # some additional information, like a site indicator. If there is
    # only one dot in HOSTNAME, we assume this is already a short
    # name.
    case ${#${HOSTNAME//[^.]/}} in
        0|1) HOST=$HOSTNAME ;;
        2) HOST=${HOSTNAME%%.*} ;;
        3)
            local next=${${HOSTNAME#*.}%%.*}
            (( ${#next} >= 2 && ${#next} <= 4 )) && HOST=$HOST.$next
            ;;
    esac
} && __ 2> /dev/null
