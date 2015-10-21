# -*- sh -*-

_vbe_autoload () {
    # Like autoload but actually load and fail silently if not able to load
    (( $+functions[$1] )) && return 0
    autoload +X $1 2> /dev/null || {
        unset -f $1
        return 1
    }
    return 0
}

_vbe_autoload is-at-least || is-at-least() { return 0 }

# Test for unicode support
_vbe_can_do_unicode () {
    if is-at-least 4.3.4 && \
           [[ -o multibyte ]] && (( ${#${:-↵}} == 1 )); then
        case $TERM in
            screen*) ;;
            xterm*) ;;
            rxvt*) ;;
            *) return 1 ;;
        esac
        return 0
    fi
    return 0
}
