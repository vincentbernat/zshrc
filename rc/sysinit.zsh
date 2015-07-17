# -*- sh -*-

# System init-related aliases
__() {
    local -a cmds
    cmds=(start stop reload restart status)
    local sudo
    (( $UID == 0 )) || sudo=sudo

    if [ -d /run/systemd/system ]; then
        # systemd
        for cmd ($cmds) {
            compdef -d $cmd
            alias   $cmd="$sudo systemctl $cmd"
        }
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
        for cmd ($cmds) {
            compdef _services $cmd
        }
    fi

} && __
