# -*- sh -*-

if [ -z "$ZSH_VERSION" ]; then
    unset LC_ALL
    eval export $(zsh -c \
                  "typeset PATH
                   typeset NIX_PROFILES NIX_SSL_CERT_FILE LOCALE_ARCHIVE
                   typeset FONTCONFIG_FILE GOPATH XDG_DATA_DIRS
                   typeset LC_ALL $(locale 2> /dev/null | sed 's/=.*//' | tr '\n' ' ')
                  ")
    return
fi

# It's possible to reimport PATH into user session with:
#  systemctl --user import-environment PATH

# Compute a PATH without duplicates. This could have been done with
# "typeset -aU" but some paths are equal, like /usr/bin and /bin when
# symlinked. We want to keep symlinks because some of them may move
# (for example, Nix).
() {
    [[ $IN_NIX_SHELL == pure ]] && return
    local -a wanted savedpath
    local p
    [[ -f /etc/os-release ]] && wanted=(
        ~/.local/bin/${${(M@f)$(</etc/os-release):#ID=*}#ID=}
    )
    wanted=(
        $wanted
        # User-local directories
        ~/.local/bin
        ~/.nix-profile/bin
        # Locally-installed software
        /nix/var/nix/profiles/default/bin
        /usr/lib/ccache
        /usr/local/sbin
        /usr/local/bin
        /var/lib/flatpak/exports/bin
        /snap/bin
        # Vendor-installed software
        /usr/cumulus/bin
        # Regular paths
        /usr/sbin
        /usr/bin
        /sbin
        /bin
        /usr/games
    )
    savedpath=($path)
    path=()
    # First, put paths from savedpaths not in the wanted list
    for p in $savedpath; do
	(( 0 )) \
            || (( ${${wanted[(r)$p]}:+1} )) \
            || (( ${${wanted[(r)${p:A}]}:+1} )) \
            || (( ${${path[(r)${p}]}:+1} )) \
            || (( ${${path[(r)${p:A}]}:+1} )) \
            || {
	    [[ -d ${p:A} ]] && path=($path $p)
	}
    done
    # Then, put paths in the wanted list
    for p in $wanted; do
	(( ${${path[(r)${p:A}]}:+1} )) || {
	    [[ -d ${p:A} ]] && path=($path $p)
	}
    done

    export PATH
}

() {
    [[ $IN_NIX_SHELL == pure ]] && return

    local -aU xdg_data_dirs profiles
    xdg_data_dirs=(~/.local/share ~/.nix-profile/share ${(ps.:.)XDG_DATA_DIRS})
    export XDG_DATA_DIRS=${(pj.:.)xdg_data_dirs}

    profiles=(
        /run/current-system/sw
        /nix/var/nix/profiles/default
        /nix/var/nix/profiles/per-user/$USER
        $HOME/.nix-profile
    )
    profiles=(${^profiles}(N-/))
    export NIX_PROFILES=${profiles}

    export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
    [ -f $NIX_SSL_CERT_FILE ] || unset NIX_SSL_CERT_FILE
    export LOCALE_ARCHIVE=$HOME/.nix-profile/lib/locale/locale-archive
}

[[ -n $IN_NIX_SHELL ]] && [[ $IN_NIX_SHELL != pure ]] && \
    export FONTCONFIG_FILE=$(nix eval --raw nixpkgs'#'fontconfig.out.outPath)/etc/fonts/fonts.conf

[[ -d $HOME/src ]] && export GOPATH=$HOME/src/gocode
export GOPROXY=direct

unset TERM_PROGRAM TERM_PROGRAM_VERSION
unset MAILCHECK

# Don't use distribution-provided RC files
setopt no_global_rcs

# fpath
ZSH=${ZSH:-${ZDOTDIR:-$HOME}/.zsh}
fpath=(
    # Custom functions and completions
    $ZSH/functions $ZSH/completions
    # For nix-shell, add share/zsh for elements in PATH (for nix shell), as well as profiles.
    ${^${(M)path:#/nix/store/*}}/../share/zsh/{site-functions,$ZSH_VERSION/functions,vendor-completions}(N-/)
    ${^${(z)NIX_PROFILES}}/share/zsh/{site-functions,$ZSH_VERSION/functions,vendor-completions}(N-/)
    # Default fpath
    $fpath
)
[[ $ZSH_NAME == "zsh-static" ]] && [[ -d /usr/share/zsh-static ]] && {
    # Rewrite /usr/share/zsh to /usr/share/zsh-static
    fpath=(${fpath/\/usr\/share\/zsh\//\/usr\/share\/zsh-static\/})
}
autoload -U $ZSH/functions/*(.:t)
