# -*- sh -*-

# Compute a sensible TERM and set colors
autoload -Uz zsh/terminfo zsh/termcap
() {
    local term
    local -aU terms

    # Special case when running as Emacs, dumb doesn't have a terminfo
    # entry, try dumb-emacs-ansi instead.
    if [[ $TERM = dumb ]] && [[ -n $INSIDE_EMACS ]]; then
        LC__ORIGINALTERM=dumb-emacs-ansi
    fi

    terms=($LC__ORIGINALTERM           # Received by SSH (see ssh.rc)
           # Current TERM with -256color appended when over SSH
           ${SSH_CONNECTION+${TERM%-256color}-256color}
           $TERM                       # Current TERM
           ${TERM%-256color}           # Current TERM without -256color
           xterm-256color              # Well-known TERM
           xterm)                      # Even more well-known TERM
    for term in $terms; do
        TERM=$term 2> /dev/null
        if (( ${terminfo[colors]:-0} >= 8 )) || \
            (zmodload zsh/termcap 2> /dev/null) && \
            (( ${termcap[Co]:-0} >= 8)); then
            break
        fi
    done
    unset LC__ORIGINALTERM
    export TERM
}

() {
    # Test for unicode support
    #
    # We need:
    #  1. multibyte input support
    #  2. locale support + correct width
    #  3. terminal support
    #
    # Locale support is tested by trying to output an unicode
    # character. Zsh will choke with "character not in range" if this
    # doesn't work. Correct width is checked by asking Zsh to pad a
    # recent double-width unicode character. Both tests are combined.
    #
    # Funny fact: wcwidth() returns -1 when it doesn't know the width.
    # So, the expression value below could be 3 if wcwidth() knows the
    # correct width, 4 if it does not (it returns 1), but it could be
    # 5 if wcwidth() has no clue about the character at all and
    # returns -1.
    #
    # Source for width checking:
    # https://unix.stackexchange.com/questions/245013/get-the-display-width-of-a-string-of-characters/591447#591447
    local _vbe_can_do_unicode=0
    [[ -o multibyte ]] || return
    case $TERM in screen*|xterm*|rxvt*) ;; *) return ;; esac
    (( ${#${:-$(print -n "\u21B5\u21B5" 2> /dev/null)}} == 2 )) || return
    _vbe_can_do_unicode=1
    (( ${#${(ml[4])${:-$(print -n "\U1f40b" 2> /dev/null)}}} == 3 )) && _vbe_can_do_unicode=2

    typeset -gA PRCH
    if (( _vbe_can_do_unicode )); then
        PRCH=(
            sep $'\uE0B1' end $'\uE0B0'
            retb "" reta $' \u2717'
            circle $'\u25CF' branch $'\uE0A0'
            ok $'\u2713' ellipsis $'\u2026'
            eol $'\u23CE' running $'\u21BB'
            elapsed $'\u231b'
        )
    else
        PRCH=(
            sep "/" end ""
            retb "<" reta ">"
            circle "*" branch "\`|"
            ok ">" ellipsis ".."
            eol "~~" running "> "
            elapsed ''
        )
    fi
    if (( _vbe_can_do_unicode > 1 )); then
        PRCH=(
            ${(qkv)PRCH}
            python $'\U1f40d'
            docker $'\U1f40b'
            nix $'\u2744\ufe0f '
        )
    else
        PRCH=(
            ${(qkv)PRCH}
            python "python"
            docker "docker"
            nix "nix"
        )
    fi
}

# Freeze the terminal
ttyctl -f
