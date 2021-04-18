# -*- sh -*-

autoload -Uz is-at-least
autoload -Uz add-zsh-hook
autoload -Uz add-zle-hook-widget

[[ $ZSH_NAME == "zsh-static" ]] && is-at-least 5.4.1 && {
    # Don't tell us when modules are not available
    alias zmodload='zmodload -s'
}

zmodload -F zsh/stat b:zstat
zmodload zsh/datetime           # EPOCHSECONDS

# Test for unicode support
_vbe_can_do_unicode () {
    # We need:
    #  1. multibyte input support
    #  2. locale support + correct width
    #  3. terminal support
    #
    # Locale support is tested by trying to output an unicode
    # character. Zsh will choke with "character not in range" if this
    # doesn't work. Correct width is checked by asking Zsh to pad a
    # recent double-width unicode character. Both tests are combined.
    [[ -o multibyte ]] || return 1
    (( ${#${(ml[4])${:-$(print -n "\U1f40b" 2> /dev/null)}}} == 3 )) || return 1
    case $TERM in
        screen*|xterm*|rxvt*) return 0 ;;
    esac
    return 1
}
