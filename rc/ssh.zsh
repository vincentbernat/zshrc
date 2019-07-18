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
    # case if your TERM is somewhat special. A good fallback is
    # xterm. Most terminals are compatible with xterm and all hosts
    # have a termcap or terminfo file to handle xterm. Therefore, for
    # some values of TERM, we fallback to xterm.
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
	rxvt-256color|rxvt-unicode*)
	    LC__ORIGINALTERM=$TERM TERM=rxvt LANG=C LC_MESSAGES=C command ssh $extra "$@"
	    ;;
	screen-256color)
	    LC__ORIGINALTERM=$TERM TERM=screen LANG=C LC_MESSAGES=C command ssh $extra "$@"
	    ;;
	*)
	    LANG=C LC_MESSAGES=C command ssh $extra "$@"
	    ;;
    esac
}

# The following command implements a reverse SSH connection. This is
# to connect to hosts behind a firewall, which can connect to your
# machine but you cannot connect directly. The idea is that they issue
# a TCP connection that you will use as a tunnel to access their SSH
# port.
#
# I am using this to connect to VM using user-mode network (QEMU, KVM,
# UML, ...).
rssh() {
    # We should probe for a free port, but is it easy?
    local port
    port=$((21422 + $RANDOM % 1000))

    print "On remote host, use \`socat TCP:10.0.2.2:$port TCP:127.0.0.1:22\` to allow SSH access... "
    ssh -oProxyCommand="socat TCP-LISTEN:$port,bind=127.0.0.1,reuseaddr STDIO" \
        "$@"
}

# Invoke this shell on a remote host. All arguments are passed to SSH,
# but we expect to use this for interactive shells only. Several
# connections may be needed to install the appropriate files. It
# shadows the "zssh" command which enables interactive transfers over
# ssh with zmodem.
zssh() {
    local -a common
    local state

    common=(-o ControlPath="$ZSH/run/zssh-%C")
    command ssh -n -o ControlPersist=5s -o ControlMaster=auto $common "$@" "
# Check if zsh is installed.
if ! which zsh 2> /dev/null > /dev/null; then
    echo no-zsh
    exit 0
fi

# Check if dotfiles are up-to-date
# If dotfiles are already up-to-date, execute the shell
current=\$(cat ~/.zsh.$USER/run/version 2> /dev/null || echo 0)
target=$(sed -n 's/^version=//p' $ZSH/run/zsh-install.sh)
if [ \$current  = \$target  ]; then
    echo ok
    exit 0
fi

# Otherwise signal we want to install
echo need-update
" | read state
    case $state in
        no-zsh)
            # No zsh, plain SSH connection
            print -u2 "[!] ZSH is not installed on remote"
            ssh $common "$@"
            ;;
        ok)
            # Dotfiles up-to-date, connect and execute zsh
            ssh $common -t "$@" \
                "export ZDOTDIR=~/.zsh.$USER && export ZSH=~/.zsh.$USER && export SHELL=\$(which zsh) && exec zsh -i -l -d"
            ;;
        need-update)
            # We need to install dotfiles, connect and execute zsh
            print -u2 "[*] Installing dotfiles..." \
                && cat $ZSH/run/zsh-install.sh \
                    | command ssh $common -C "$@" \
                              "export ZDOTDIR=~/.zsh.$USER && export ZSH=~/.zsh.$USER && exec sh -s" \
                && print -u2 "[*] Spawning remote zsh..." \
                && ssh $common -t "$@" \
                       "export ZDOTDIR=~/.zsh.$USER && export ZSH=~/.zsh.$USER && export SHELL=\$(which zsh) && exec zsh -i -l -d"
            ;;
        *)
            return 1
            ;;
    esac
}
(( $+functions[compdef] )) && compdef _ssh zssh=ssh
