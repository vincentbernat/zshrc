# -*- sh -*-

autoload is-at-least
autoload add-zsh-hook
autoload add-zle-hook-widget

[[ $ZSH_NAME == "zsh-static" ]] && is-at-least 5.4.1 && {
    # Don't tell us when modules are not available
    alias zmodload='zmodload -s'
}

zmodload -F zsh/stat b:zstat
zmodload zsh/datetime           # EPOCHSECONDS

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
            (( ${#${:-$(print -n "\u21B5\u21B5" 2> /dev/null)}} == 2 )); then
        case $TERM in
            screen*|xterm*|rxvt*) return 0 ;;
        esac
    fi
    return 1
}
