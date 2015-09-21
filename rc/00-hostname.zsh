# -*- sh -*-

__() {
    # Export HOSTNAME variable (fully qualified hostname)
    integer step=0
    while true; do
        # Try various alternatives
        case $step in
            0) HOSTNAME=$HOST ;;
            1) HOSTNAME=$(</etc/hostname) ;;
            2) HOSTNAME="$(hostname -f)" ;;
            3) HOSTNAME=${${(M)${${(ps: :)${:-"$(getent hosts $HOST)"}}[2,-1]}:#*.*}[1]} ;;
            4) HOSTNAME=$HOST.$(</etc/mailname) ;;
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
            (( ${#next} >= 2 && ${#next} <= 4 )) && HOST=$HOST.$next
            ;;
    esac
} && __ 2> /dev/null
