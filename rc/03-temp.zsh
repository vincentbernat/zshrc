# -*- sh -*-

[[ -n $IN_NIX_SHELL ]] && () {
    # nix-shell configure temporary directory to /run/user/$UID. Why?
    # (this is not the case for "nix shell")
    local v
    for v in TMP TMPDIR TEMP TEMPDIR; do
        [[ ${(P)v} = "/run/user/$UID" ]] && \
            unset $v
    done
}
