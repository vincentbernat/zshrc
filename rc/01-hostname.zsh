# -*- sh -*-

() {
    # Export HOSTNAME variable (fully qualified hostname)
    integer step=1
    while true; do
        # Try various alternatives. As getent hosts try IPv6 first, then v4
        # (because of gethostbyname2()) and for the local hostname, we are
        # unlikely to have it in /etc/hosts, we try with ahostsv4, which calls
        # getaddrinfo() with AF_INET.
        case $step in
            1) HOSTNAME=$(</etc/hostname) ;;
            2) HOSTNAME="$(hostname -f)" ;;
            3) HOSTNAME=${${${(@f)${:-"$(LOCALDOMAIN= RES_TIMEOUT=1 RES_DFLRETRY=0 getent ahostsv4 $HOST)"}}##* }[1]} ;;
            4) HOSTNAME=${${(M)${(ps: :)${${(@f)${:-"$(LOCALDOMAIN= RES_TIMEOUT=1 RES_DFLRETRY=0 getent hosts $HOST)"}}#* }}:#*.*}[1]} ;;
            5) HOSTNAME=$HOST.${${(s: :)${${(@M)${(f)$(</etc/resolv.conf)}:#domain*}[1]}}[2]} ;;
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
            local next0=${next%%[0-9]*}
            (( ${#next0} >= 2 && ${#next0} <= 5 )) && HOST=${HOSTNAME%%.*}.$next
            ;;
    esac
} 2> /dev/null
