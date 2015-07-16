# -*- sh -*-

# Get the first non optional argument
_vbe_first_non_optional_arg() {
    local args
    args=( "$@" )
    args=( ${(R)args:#-*} )
    print -- $args[1]
}

# Test for unicode support
_vbe_can_do_unicode () {
    if is-at-least 4.3.4 && [[ -o multibyte ]] && (( ${#${:-↵}} == 1 )); then
        case $TERM in
            screen*) ;;
            xterm*) ;;
            rxvt*) ;;
            *) return 1 ;;
        esac
        return 0
    fi
    return 1
}
