# -*- sh -*-

ssh() {
    # Modify the title of the current by using LocalCommand option.
    local -a extra
    extra=(-o PermitLocalCommand=yes
           -o LocalCommand="$ZSH/run/u/$HOST-$UID/title \"> ssh %n\" ${PRCH[running]}%n")

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
    # something in `$ZSH/rc/00-terminfo.zsh` to restore the
    # appropriate terminal (saved in `LC__ORIGINALTERM`).
    #
    # The problem is quite similar for LANG and LC_MESSAGES. We reset
    # them to C to avoid any problem with hosts not having your
    # locally installed locales. See this post for more details on
    # this:
    #    http://vincent.bernat.im/en/blog/2011-zsh-zshrc.html
    #
    # Also, when the same ZSH configuration is used on the remote
    # host, the locale is reset with the help of
    # `$ZSH/rc/01-locale.zsh`.
    case "$TERM" in
	*-*)
	    LC__ORIGINALTERM=$TERM TERM=${TERM%%-*} LANG=C LC_MESSAGES=C command ssh $extra "$@"
	    ;;
	*)
	    LANG=C LC_MESSAGES=C command ssh $extra "$@"
	    ;;
    esac
}

# Invoke this shell on a remote host. All arguments are passed to SSH,
# but we expect to use this for interactive shells only. Several
# connections may be needed to install the appropriate files. It
# shadows the "zssh" command which enables interactive transfers over
# ssh with zmodem.
zssh() {
    local -a common
    local state
    local execzsh

    [[ -f $ZSH/run/zsh-install.sh ]] || install-zsh
    common=(-o ControlPath="$ZSH/run/%r@%h:%p")
    execzsh="export ZDOTDIR=~/.zsh.$USER \
      && export ZSH=~/.zsh.$USER \
      && export SHELL=\$(which zsh) \
      && uname -a \
      && (cat /etc/motd 2>/dev/null;:) \
      && exec zsh -i -l"
    command ssh -n -o ControlPersist=5s -o ControlMaster=auto $common "$@" "
# Check if zsh is installed.
if ! which zsh 2> /dev/null > /dev/null; then
    if grep -Eq '^ID=(debian|ubuntu)\$' /etc/os-release 2> /dev/null && [ x\$USER = xroot ]; then
        echo no-zsh-but-debian
    else
        echo no-zsh
    fi
    exit 0
fi

# Check if dotfiles are up-to-date
# If dotfiles are already up-to-date, execute the shell
current=\$(cat ~/.zsh.$USER/run/version 2> /dev/null || echo 0)
target=$(sed -n 's/^version=//p' $ZSH/run/zsh-install.sh)
if [ x\$current = x\$target ]; then
    echo ok
    exit 0
fi

# Otherwise signal we want to install
echo need-update
" | read state
    case $state in
        ok)
            # Dotfiles up-to-date, connect and execute zsh
            ssh $common -t "$@" $execzsh
            ;;
        no-zsh)
            # No zsh, plain SSH connection
            print -u2 "[!] ZSH is not installed on remote"
            ssh $common "$@"
            ;;
        no-zsh-but-debian)
            # No zsh but remote is Debian
            print -u2 "[*] Installing Zsh..." \
                && command ssh -n $command -C "$@" "DEBIAN_FRONTEND=noninteractive apt-get -qq -y install zsh mg" \
                || {
                    print -u2 "[!] Cannot install ZSH"
                    ssh $common "$@"
                    return
                }
            ;&
        need-update)
            # We need to install dotfiles, connect and execute zsh
            print -u2 "[*] Installing dotfiles..." \
                && cat $ZSH/run/zsh-install.sh \
                    | command ssh $common -C "$@" \
                              "export ZDOTDIR=~/.zsh.$USER && export ZSH=~/.zsh.$USER && exec sh -s" \
                && print -u2 "[*] Spawning remote zsh..." \
                && ssh $common -t "$@" $execzsh
            ;;
        *)
            return 1
            ;;
    esac
}
(( $+functions[compdef] )) && compdef _ssh zssh=ssh

# Connect with agent-forwarding enabled but using a locked-down SSH
# agent. This assumes the key used to connect to the server will be
# the only one needed.
alias assh="ssh-agent ssh -o AddKeysToAgent=confirm -o ForwardAgent=yes"
