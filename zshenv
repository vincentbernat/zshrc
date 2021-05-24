# -*- sh -*-

if [ -z "$ZSH_VERSION" ]; then
    unset LC_ALL
    eval export $(zsh -c \
                  "typeset PATH
                   typeset NIX_PATH NIX_PROFILES NIX_SSL_CERT_FILE LOCALE_ARCHIVE
                   typeset FONTCONFIG_FILE GOPATH
                   typeset LC_ALL $(locale 2> /dev/null | sed 's/=.*//' | tr '\n' ' ')
                  ")
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

# Compute NIX_PATH with deduplication
() {
    [[ $IN_NIX_SHELL == pure ]] && return
    [[ ! -d $HOME/.nix-defexpr/channels ]] && return

    local -aU nix_path
    nix_path=(${(ps.:.)NIX_PATH} ~/.nix-defexpr/channels)

    export NIX_PATH=${(pj.:.)nix_path}
    export NIX_PROFILES="/nix/var/nix/profiles/default $HOME/.nix-profile"
    export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    export LOCALE_ARCHIVE=$HOME/.nix-profile/lib/locale/locale-archive
}

[[ -z $IN_NIX_SHELL ]] || {
    export FONTCONFIG_FILE=$(nix eval --raw nixpkgs.fontconfig.out.outPath)/etc/fonts/fonts.conf
}

[[ -d $HOME/src ]] && export GOPATH=$HOME/src/gocode

unset MAILCHECK
