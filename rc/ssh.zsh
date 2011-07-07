# -*- sh -*-

ssh() {
    title "$@"
    case "$TERM" in
	rxvt-256color|rxvt-unicode*)
	    TERM=xterm LANG=C LC_MESSAGES=C command ssh "$@"
	    ;;
	*)
	    LANG=C LC_MESSAGES=C command ssh "$@"
	    ;;
    esac
}
