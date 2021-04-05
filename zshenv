# -*- sh -*-

# This file needs to be also sourceable from a POSIX shell.

# Nix stuff. Mostly, this is just about doing that:
#  env > a
#  . ~/.nix-profile/etc/profile.d/nix.sh
#  env > b
#  diff -u a b
[ x$IN_NIX_SHELL != xpure ] && [ -d $HOME/.nix-defexpr/channels ] && {
    [ -n "$NIX_PATH" ] || \
        export NIX_PATH=$HOME/.nix-defexpr/channels
    [ -n "$NIX_SSL_CERT_FILE" ] || \
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
}
export GOPATH=$HOME/src/gocode

if [ -z "$ZSH_VERSION" ]; then
    eval $(zsh -c 'typeset PATH')
    export PATH
    return
fi

# Compute a PATH without duplicates. This could have been done with
# "typeset -aU" but some paths are equal, like /usr/bin and /bin when
# symlinked. We want to keep symlinks because some of them may move
# (for example, Nix).
() {
    [[ $IN_NIX_SHELL == pure ]] && return
    local -a wanted savedpath
    local p
    wanted=(~/bin
            ~/.nix-profile/bin
            /usr/lib/ccache
            /usr/local/sbin
            /usr/local/bin
            /var/lib/flatpak/exports/bin
            /usr/cumulus/bin
            /usr/sbin
            /usr/bin
            /sbin
            /bin
            /usr/local/games
            /usr/games)
    savedpath=($path)
    path=()
    # First, put paths from savedpaths not in the wanted list
    for p in $savedpath; do
	(( ${${wanted[(r)$p]}:+1} )) || (( ${${path[(r)${p:A}]}:+1} )) || {
	    [ -d ${p:A} ] && path=($path $p)
	}
    done
    # Then, put paths in the wanted list
    for p in $wanted; do
	(( ${${path[(r)${p:A}]}:+1} )) || {
	    [ -d ${p:A} ] && path=($path $p)
	}
    done

    export PATH
}

[ x$IN_NIX_SHELL = x ] || {
    export FONTCONFIG_FILE=$(nix eval --raw nixpkgs.fontconfig.out.outPath)/etc/fonts/fonts.conf
}
