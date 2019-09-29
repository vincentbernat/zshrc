# -*- sh -*-

# Create a temporary directory
[ ! -h ~/tmp ] && [ ! -d ~/tmp ] && [ -w ~ ] && [[ -z $SUDO_USER ]] && \
    mkdir ~/tmp

[[ -n $IN_NIX_SHELL ]] && () {
    # Nix configure temporary directory to /run/user/$UID. Why?
    local v
    for v in TMP TMPDIR TEMP TEMPDIR; do
        [[ ${(P)v} = "/run/user/$UID" ]] && \
            export $v=/tmp
    done
}
