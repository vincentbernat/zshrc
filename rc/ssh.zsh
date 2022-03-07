# -*- sh -*-

_vbe_ssh_command() {
    # We assume we have an OpenSSH client with this patch:
    #  https://bugzilla.mindrot.org/attachment.cgi?id=3547
    local remote=${${=${(M)${:-"${(@f)$(command ssh -G "$@" 2>/dev/null)}"}:#(host|hostname) *}[1]}[-1]}
    [[ -n $remote ]] &&
        _vbe_title ${PRCH[remote]}${remote}

    # TERM is one of the variables that is usually allowed to be
    # transmitted to the remote session. The remote host should have
    # the appropriate termcap or terminfo file to handle the TERM you
    # provided. When connecting to random hosts, this may not be the
    # case if your TERM is somewhat special. A good fallback is xterm,
    # but nowadays, you can just use the basename of your current TERM
    # (screen instead of screen-256color).
    #
    # Now, you may connect to a host where your current TERM is fully
    # supported and you will get xterm instead (which means 8 base
    # colors only). There is no clean solution for this. You may want
    # to reexport the appropriate TERM when logged on the remote host
    # or use commands like this:
    #     ssh -t XXXXX env TERM=$TERM emacsclient -t -c
    #
    # If the remote host uses the same zshrc than this one, there is
    # something in `$ZSH/rc/02-terminfo.zsh` to restore the
    # appropriate terminal (saved in `LC__ORIGINALTERM`).
    #
    # The problem is quite similar for LANG and LC_MESSAGES. We reset
    # them to C to avoid any problem with hosts not having your
    # locally installed locales. See this post for more details on
    # this:
    #    http://vincent.bernat.im/en/blog/2011-zsh-zshrc.html
    #
    # Also, when the same Zsh configuration is used on the remote
    # host, the locale is reset with the help of
    # `$ZSH/rc/01-locale.zsh`.
    local -a cmd
    case "$TERM" in
	*-*) cmd=(LC__ORIGINALTERM=$TERM TERM=${TERM%%-*} $cmd) ;;
    esac
    cmd=(env LANG=C LC_MESSAGES=C ssh "$@")

    # Return array in reply
    : ${(A)reply::="${cmd[@]}"}
}

ssh() {
    _vbe_ssh_command "$@"
    $reply
}

(( $+commands[sshpass] )) && [[ -f $ZSH/local/ssh2passname ]] && () {
    # Connect with a password
    pssh() {
        local passname
        local login
        local directive
        for directive in host{name,}; do
            login=$(command ssh -G "$@" \
                        | awk '($1 == "user") { user=$2 }
                               ($1 == "'$directive'") { directive=$2 }
                               END { print user "@" directive }')
            passname=$(source $ZSH/local/ssh2passname $login)
            [[ -z $passname ]] || break
        done
        [[ -n $passname ]] || {
            print -u2 "[!] No password entry found for $login!"
            return 1
        }
        print -u2 "[*] Using password entry $passname for $login"
        _vbe_ssh_command "$@"
        sshpass -f<(pass show $passname) $reply
    }
    # SCP with a password
    pscp() {
        () {
            local helper=$1
            shift
            chmod +x $helper
            scp -S $helper "$@"
        } =(<<EOF
#!$SHELL --interactive
pssh "\$@"
EOF
           ) "$@"
    }
    (( $+functions[compdef] )) && {
        compdef pssh=ssh
        compdef pscp=ssh
    }
}

# Invoke this shell on a remote host. All arguments are passed to SSH,
# but we expect to use this for interactive shells only. Several
# connections may be needed to install the appropriate files. It
# shadows the "zssh" command which enables interactive transfers over
# ssh with zmodem.
zssh() {
    local -A state
    local -a common_ssh_args
    local current=$(sed -n 's/^version=//p' $ZSH/run/zsh-install.sh)
    ! command ssh -G "$@" | command grep -q '^controlpath ' && \
        common_ssh_args=(-o ControlPath="$ZSH/run/%r@%h:%p")

    # Probe to run on remote host to check the situation.
    local __() {
        echo "state[has-zsh]"=$(if command -v zsh > /dev/null || command -v nix-build > /dev/null; then
                                    echo 1
                                else
                                    echo 0
                                fi)
        echo "state[kernel]"=$(uname -s)
        echo "state[distribution]"=$(sed -n 's/^ID=//p' /etc/os-release /usr/lib/os-release 2> /dev/null | head -1)
        echo "state[variant]"=$(sed -n 's/^VARIANT_ID=//p' /etc/os-release /usr/lib/os-release 2> /dev/null | head -1)
        echo "state[username]"=$(id -un)
        echo "state[version]"=$(cat ~/.zsh.$1/run/version 2> /dev/null || echo 0)
    }
    local probezsh="$(which __); __ $USER"

    # Execution of Zsh on remote host.
    local __() {
        set -e
        export ZDOTDIR=~/.zsh.$1
        export ZSH=~/.zsh.$1
        export SHELL=$(command -v zsh || echo $(nix-build --no-out-link "<nixpkgs>" -A zsh)/bin/zsh)
        uname -a
        cat /etc/motd 2>/dev/null || true
        exec $SHELL -i -l -d
    }
    local execzsh="$(which __); __ $USER"

    (( $#@ )) || return 1
    [[ -f $ZSH/run/zsh-install.sh ]] || install-zsh
    eval $(command ssh -n \
                   $(command ssh -G "$@" | command grep -Fxq 'controlpersist no' && print -- -o ControlPersist=5s) \
                   -o ControlMaster=auto \
                   -o PermitLocalCommand=yes \
                   -o LocalCommand="/bin/echo 'state[hostname]=%n'" \
                   $common_ssh_args "$@" \
                   ${probezsh} \
               | command grep -E '^state\[[0-9a-z-]+\]=("?)[0-9A-Za-z.-]+\1$')
    (( $#state )) || return 1

    # Install Zsh if possible
    if (( !state[has-zsh] )); then
        local cmd method
        case $state[hostname],$state[username],$state[kernel],$state[distribution],$state[variant] in
            *,root,Linux,debian,*|*,root,Linux,ubuntu,*)
                method="apt-get"
                cmd="DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends -qq -y install zsh mg > /dev/null"
                ;;
            *,root,Linux,fedora,*)
                method="dnf"
                cmd="dnf --setopt=install_weak_deps=False -qy install zsh mg"
                ;;
            *,root,OpenBSD,*)
                method="pkg-add"
                cmd="pkg_add -I zsh"
                ;;
            *,*,Linux,fedora,coreos)
                print -u2 "[.] Zsh could be installed with \`rpm-ostree install --reboot zsh'"
                ;;
            *.lab,*)
                # Only for labs as this is not considered secure to rely on third-party binaries.
                # We assume to have both wget and sudo available.
                method="zsh-bin"
                cmd='(wget -qO- https://raw.githubusercontent.com/romkatv/zsh-bin/master/install \
                   || curl -sfL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install \
                   || echo false) 2> /dev/null \
                   | sh -s -- -q -d /usr/local -e no'
                ;;
        esac
        if [[ -n $cmd ]]; then
            print -u2 "[*] Installing Zsh (with $method)..."
            if command ssh -n $common_ssh_args $command "$@" $cmd; then
                state[has-zsh]=1
            else
                print -u2 "[!] Cannot install Zsh"
            fi
        fi
    fi

    # Update dotfiles
    if (( state[has-zsh] )) \
           && [[ $state[version] != $current ]]; then
            print -u2 "[*] Updating dotfiles (from ${state[version][1,12]} to ${current[1,12]})..."
            cat $ZSH/run/zsh-install.sh \
                | command ssh $common_ssh_args -C "$@" \
                          "export ZDOTDIR=~/.zsh.$USER && export ZSH=~/.zsh.$USER && exec sh -s" \
                && state[version]=$current
    fi

    # Execute remote shell
    if (( !state[has-zsh] )); then
        print -u2 "[!] No remote zsh!"
        ssh $common_ssh_args "$@"
    elif [[ $state[version] == 0 ]]; then
        print -u2 "[!] No remote configuration!"
        ssh $common_ssh_args "$@"
    else
        print -u2 "[*] Spawning remote zsh..."
        ssh $common_ssh_args -t "$@" ${execzsh}
    fi
}
(( $+functions[compdef] )) && compdef zssh=ssh
