# -*- sh -*-

# System init-related aliases
() {
    local -a cmds
    cmds=(start stop reload restart status)
    local cmd

    if [ -d /run/systemd/system ]; then
        # systemd
        for cmd ($cmds) {
            alias $cmd="${(%):-%(#..sudo )}systemctl $cmd"
            alias u$cmd="systemctl --user $cmd"
            _vbe_autoexpand+=($cmd u$cmd)
        }
    else
        # generic service
        for cmd ($cmds) {
            function $cmd() {
                name=$1 ; shift
                ${(%):-%(#..sudo)} service $name $0 "$@"
            }
            (( $+functions[compdef] )) && compdef _services $cmd
        }
    fi

}
