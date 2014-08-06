# -*- sh -*-

# System init-related aliases
__() {
    local sudo
    (( $UID == 0 )) || sudo=sudo

    if [ -d /run/systemd/system ]; then
        # systemd
        alias   start="$sudo systemctl start"
        alias    stop="$sudo systemctl stop"
        alias  reload="$sudo systemctl reload"
        alias restart="$sudo systemctl restart"
        alias  status="$sudo systemctl status"
    elif [ -f /run/upstart-socket-bridge.pid ]; then
        # upstart
        alias   start="$sudo initctl start"
        alias    stop="$sudo initctl stop"
        alias  reload="$sudo initctl reload"
        alias restart="$sudo initctl restart"
        alias  status="$sudo initctl status"
    else
        # generic service
        function  start() {
            name=$1 ; shift
            ${(%):-%(#..sudo)} service $name start "$@"
        }
        function  stop() {
            name=$1 ; shift
            ${(%):-%(#..sudo)} service $name stop "$@"
        }
        function  reload() {
            name=$1 ; shift
            ${(%):-%(#..sudo)} service $name reload "$@"
        }
        function  restart() {
            name=$1 ; shift
            ${(%):-%(#..sudo)} service $name restart "$@"
        }
        function  status() {
            name=$1 ; shift
            ${(%):-%(#..sudo)} service $name status "$@"
        }
        compdef _services start
        compdef _services stop
        compdef _services reload
        compdef _services restart
        compdef _services status
    fi

} && __
