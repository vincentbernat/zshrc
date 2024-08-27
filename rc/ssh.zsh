# -*- sh -*-

ssh() {
    set -o localoptions -o localtraps

    local -a cmd
    cmd=(ssh "$@")

    # Get login@host. This needs OpenSSH 9.2+. See:
    #  https://bugzilla.mindrot.org/attachment.cgi?id=3547
    local -A details
    details=(${=${(M)${:-"${(@f)$(command ssh -G "$@" 2>/dev/null)}"}:#(host|hostname|user) *}})
    local remote=${details[host]:-details[hostname]}
    local login=${details[user]}@${remote}

    # Title
    [[ -n $remote ]] && (( $+functions[_vbe_title] )) && _vbe_title @${remote}

    # Password.
    # ssh-login2pass should provide the password name to use for the login
    # provided as first argument. It looks like this:
    # # -*- sh -*-
    # case $1 in
    # me@*.company.com)  print company/network/password ;;
    # me@*.company2.com) print company2/network/password ;;
    # esac
    [[ -f $ZSH/local/ssh-login2pass ]] && {
        local passname=$(source $ZSH/local/ssh-login2pass $login)
        [[ -n $passname ]] && {
            local helper=$(mktemp)
            trap "command rm -f $helper" EXIT INT
            # The helper uses pass on first try, then display a login prompt if
            # there is a working TTY.
            <<EOF > $helper
#!$SHELL
if [ -k $helper ]; then
  {
    oldtty=\$(stty -g)
    trap 'stty \$oldtty < /dev/tty 2> /dev/null' EXIT INT TERM HUP
    stty -echo
    printf "\r%s password: " "${(q)login}"
    read password
    printf "\n"
  } > /dev/tty < /dev/tty
  printf "%s" "\$password"
else
  pass show $passname | head -1
  chmod +t $helper
fi
EOF
            chmod u+x $helper
            cmd=(SSH_ASKPASS=$helper SSH_ASKPASS_REQUIRE=prefer $cmd)
        }
    }

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
    #    https://vincent.bernat.ch/en/blog/2011-zsh-zshrc.html
    #
    # Also, when the same Zsh configuration is used on the remote
    # host, the locale is reset with the help of
    # `$ZSH/rc/01-locale.zsh`.
    [[ $TERM = *-* ]] && cmd=(LC__ORIGINALTERM=$TERM TERM=${TERM%%-*} $cmd)
    cmd=(LANG=C LC_MESSAGES=C LC_CTYPE=C LC_TIME=C LC_NUMERIC=C $cmd)

    env $cmd
}

scp() {
    () {
        local helper=$1
        shift
        chmod +x $helper
        command scp -S $helper "$@"
    } =(<<EOF
#!$SHELL
source ${(%):-%x}
ssh "\$@"
EOF
       ) "$@"
}

# Invoke this shell on a remote host. All arguments are passed to SSH,
# but we expect to use this for interactive shells only. Several
# connections may be needed to install the appropriate files. It
# shadows the "zssh" command which enables interactive transfers over
# ssh with zmodem.
zssh() {
    local -x LANG=C LC_MESSAGES=C LC_CTYPE=C LC_TIME=C LC_NUMERIC=C
    local -A state
    local -a common_ssh_args probe_ssh_args
    local current=$(sed -n 's/^version=//p' $ZSH/run/zsh-install.sh)
    ! command ssh -G "$@" 2> /dev/null | command grep -q '^controlpath ' && \
        common_ssh_args=(-o ControlPath="$ZSH/run/%r@%h:%p")
    prepare_ssh_args=(-n -o ClearAllForwardings=yes -o ControlMaster=auto)
    command ssh -G "$@" 2> /dev/null | command grep -Fxq 'controlpersist no' && \
        prepare_ssh_args=($prepare_ssh_args -o ControlPersist=10s)

    # Probe to run on remote host to check the situation (POSIX shell)
    local __() {
        echo "state[has-zsh]"=$(if PATH=$PATH:$HOME/.local/bin command -v zsh > /dev/null ||
                                        command -v nix-build > /dev/null; then
                                    echo 1
                                else
                                    echo 0
                                fi)
        echo "state[kernel]"=$(uname -s)
        echo "state[distribution]"=$(sed -n 's/^ID=//p' /etc/os-release /usr/lib/os-release 2> /dev/null | head -1)
        echo "state[variant]"=$(sed -n 's/^VARIANT_ID=//p' /etc/os-release /usr/lib/os-release 2> /dev/null | head -1)
        echo "state[username]"=$(id -un)
        if [ "$(id -un)" = "$1" ]; then
            echo "state[location]"=home
            echo "state[version]"=$(cat ~/.zsh/run/version 2> /dev/null || echo 0)
        else
            echo "state[location]"=private
            echo "state[version]"=$(cat ~/.zsh.$1/run/version 2> /dev/null || echo 0)
        fi
    }
    local probezsh="sh -c '$(which __); __ $USER'"

    (( $#@ )) || return 1
    [[ -f $ZSH/run/zsh-install.sh ]] || install-zsh
    # Eval remote state: grep call is important to make it safe
    eval $(command ssh \
                   -o PermitLocalCommand=yes \
                   -o LocalCommand="/bin/echo 'state[hostname]=%n'" \
                   $prepare_ssh_args \
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
                cmd="(export DEBIAN_FRONTEND=noninteractive \
                   && apt-get -qqy update \
                   && apt-get --no-install-recommends -qqy install zsh mg) > /dev/null"
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
                method="zsh-bin"
                cmd='(wget -qO- https://raw.githubusercontent.com/romkatv/zsh-bin/master/install \
                   || curl -sfL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install \
                   || echo false) 2> /dev/null \
                   | sh -s -- -q -d ~/.local -e no'
                ;;
        esac
        if [[ -n $cmd ]]; then
            print -u2 "[*] Installing Zsh (with $method)..."
            if command ssh $prepare_ssh_args $common_ssh_args $command "$@" $cmd; then
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
            { if [[ $state[location] == "private" ]]; then
                  echo "export ZDOTDIR=\$HOME/.zsh.$USER"
                  echo "export ZSH=\$HOME/.zsh.$USER"
              fi
              cat $ZSH/run/zsh-install.sh } \
                | command ssh -o ClearAllForwardings=yes $common_ssh_args -C "$@" \
                          sh -es \
                && state[version]=$current
    fi

    # Execution of Zsh on remote host (POSIX shell)
    local __() {
        set -e
        export PATH=$PATH:$HOME/.local/bin
        if [ $2 = "private" ]; then
            export ZDOTDIR=$HOME/.zsh.$1
            export ZSH=$HOME/.zsh.$1
        fi
        export SHELL=$(command -v zsh)
        [ -n "$SHELL" ] || \
            SHELL=$(nix-build --no-out-link "<nixpkgs>" -A zsh 2> /dev/null ||
                    nix eval --raw nixpkgs#zsh.out.outPath 2> /dev/null)/bin/zsh
        uname -a
        cat /etc/motd 2>/dev/null || true
        unset SHLVL
        exec $SHELL -i -l -d
    }
    local execzsh="sh -c '$(which __); __ $USER $state[location]'"

    # Execute remote shell
    if (( !state[has-zsh] )); then
        print -u2 "[!] No remote zsh!"
        ssh $common_ssh_args "$@"
    elif [[ $state[version] == 0 ]]; then
        print -u2 "[!] No remote configuration!"
        ssh $common_ssh_args "$@"
    else
        print -u2 "[*] Spawning remote zsh..."
        ssh $common_ssh_args -t "$@" "${execzsh}"
    fi
}
(( $+functions[compdef] )) && compdef zssh=ssh
