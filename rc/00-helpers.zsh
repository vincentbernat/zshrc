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
    # We need:
    #  1. at least zsh 4.3.4
    #  2. multibyte input support
    #  3. locale support
    #  4. terminal support
    # Locale support is tested by trying to output an unicode
    # character. zsh will choke with "character not in range" if this
    # doesn't work.
    if is-at-least 4.3.4 && \
            [[ -o multibyte ]] && \
            (( ${#${:-$(print -n "\u21B5" 2> /dev/null)}} == 1 )); then
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
