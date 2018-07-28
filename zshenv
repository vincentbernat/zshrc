# -*- sh -*-

# This file needs to be also sourceable from a POSIX shell.

# Nix stuff. Mostly, this is just about doing that:
#  env > a
#  . ~/.nix-profile/etc/profile.d/nix.sh
#  env > b
#  diff -u a b
[ -d $HOME/.nix-defexpr/channels/nixpkgs ] && {
    [ -n "$NIX_PATH" ] || \
        export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/channels/nixpkgs
    [ -n "$NIX_SSL_CERT_FILE" ] || \
        export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
}

export GOPATH=$HOME/src/gocode

if [ -z "$ZSH_VERSION" ]; then
    eval $(zsh -c 'typeset -gpx PATH')
    return
fi

() {
    local -a wanted savedpath
    local p
    wanted=(~/bin ~/.nix-profile/bin /usr/lib/ccache
            /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin
            /usr/local/games /usr/games)
    savedpath=($path)
    path=()
    for p in $savedpath; do
	(( ${${wanted[(r)$p]}:+1} )) || (( ${${path[(r)${p:A}]}:+1} )) || {
	    [ -d ${p:A} ] && path=($path $p)
	}
    done
    for p in $wanted; do
	(( ${${path[(r)${p:A}]}:+1} )) || {
	    [ -d ${p:A} ] && path=($path $p)
	}
    done

    export PATH
}
