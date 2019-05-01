# -*- sh -*-

() {
    # Export HOSTNAME variable (fully qualified hostname)
    integer step=1
    while true; do
        # Try various alternatives
        case $step in
            1) HOSTNAME=$(</etc/hostname) ;;
            2) HOSTNAME="$(hostname -f)" ;;
            3) HOSTNAME=${${(M)${${(ps: :)${:-"$(LOCALDOMAIN= RES_TIMEOUT=1 getent hosts $HOST)"}}[2,-1]}:#*.*}[1]} ;;
            4) [[ $HOST != $(</etc/mailname) ]] && HOSTNAME=$HOST.$(</etc/mailname) ;;
            5) HOSTNAME=$HOST.$(sed -n 's/domain //p' /etc/resolv.conf 2> /dev/null) ;;
            *) HOSTNAME=$HOST ; break ;;
        esac
        $(( step++ ))
        HOSTNAME=${HOSTNAME%%.}
        [[ $HOSTNAME == *.* ]] && break
    done
    export HOSTNAME

    # We put a short name in HOST. However, we may extend it by adding
    # some additional information, like a site indicator. If there is
    # only one dot in HOSTNAME, we assume this is already a short
    # name.
    case ${#${HOSTNAME//[^.]/}} in
        0) HOST=$HOSTNAME ;;
        1) HOST=${${HOSTNAME%.local}%.localdomain} ;;
        2) HOST=${HOSTNAME%%.*} ;;
        *)
            local next=${${HOSTNAME#*.}%%.*}
            (( ${#next} >= 2 && ${#next} <= 4 )) && HOST=${HOSTNAME%%.*}.$next
            ;;
    esac
} 2> /dev/null
