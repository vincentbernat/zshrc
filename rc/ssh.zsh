# -*- sh -*-

_vbe_ssh() {
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
	    LC__ORIGINALTERM=$TERM TERM=rxvt LANG=C LC_MESSAGES=C command ssh "$@"
	    ;;
	screen-256color)
	    LC__ORIGINALTERM=$TERM TERM=screen LANG=C LC_MESSAGES=C command ssh "$@"
	    ;;
	*)
	    LANG=C LC_MESSAGES=C command ssh "$@"
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

(( $+commands[tmux] )) && [[ -n $TMUX ]] && {

    # Execute a command in a new pane and synchronise all panes. This
    # is a replacement of cluster-ssh. Here is how to execute it:
    #
    # tmux-cssh web-{001..005}.adm.dailymotion.com
    #
    function tmux-cssh() {
        local host
        local window
        for host in "$@"; do
            if [[ -z $window ]]; then
                window=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' "ssh $host")
            else
                tmux split-window -t $window "ssh $host"
                tmux select-layout -t $window tiled
            fi
        done
        tmux set-window-option -t $window synchronize-panes on
        tmux select-window -t $window
    }
}
