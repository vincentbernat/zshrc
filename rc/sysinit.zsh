# -*- sh -*-

# System init-related aliases
__() {
    local -a cmds
    cmds=(start stop reload restart status)
    local sudo cmd
    (( $UID == 0 )) || sudo=sudo

    if [ -d /run/systemd/system ]; then
        # systemd
        for cmd ($cmds) {
            compdef -d $cmd
            alias   $cmd="$sudo systemctl $cmd"
        }
    else
        # generic service
        for cmd ($cmds) {
            function  $cmd() {
                name=$1 ; shift
                ${(%):-%(#..sudo)} service $name $0 "$@"
            }
            compdef _services $cmd
        }
    fi

} && __
