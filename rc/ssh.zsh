# -*- sh -*-

ssh() {
    _vbe_title "$@"
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
    # appropriate terminal (saved in `ORIGINALTERM`).
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
	    ORIGINALTERM=$TERM TERM=xterm LANG=C LC_MESSAGES=C command ssh "$@"
	    ;;
	*)
	    LANG=C LC_MESSAGES=C command ssh "$@"
	    ;;
    esac
}
