# -*- sh -*-

TERMINFO_DIRS=$ZSH/run/terminfo:$HOME/.terminfo:/etc/terminfo

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
           ${TERM%-*}                  # Current TERM without right part
           xterm-256color              # Well-known TERM
           xterm)                      # Even more well-known TERM
    for term in $terms; do
        unset TERMCAP
        [[ -f $ZSH/run/$term.termcap ]] && TERMCAP=$ZSH/run/$term.termcap
        TERM=$term 2> /dev/null
        if (( ${terminfo[colors]:-0} >= 8 )) || \
            (zmodload zsh/termcap 2> /dev/null) && \
            (( ${termcap[Co]:-0} >= 8)); then
            break
        fi
    done
    unset LC__ORIGINALTERM
    export TERM
    [[ -n $TERMCAP ]] && export TERMCAP
}

() {
    # Test for unicode support
    #
    # We need:
    #  1. multibyte input support
    #  2. locale support + correct width
    #  3. terminal support (for powerline)
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
    if [[ -o multibyte ]] && ! ()(( $@[(I)${TERM%%-*}] )) linux; then
        if (( ${#${:-$(print -n "\u21B5\u21B5" 2> /dev/null)}} == 2 )); then
            if (( ${#${(ml[4])${:-$(print -n "\U1f40b" 2> /dev/null)}}} == 3 )); then
                # Can do unicode with characters using several columns
                _vbe_can_do_unicode=2
            else
                # Can do unicode, but cannot determine character widths
                _vbe_can_do_unicode=1
            fi
        fi
    fi

    typeset -gA PRCH
    case $_vbe_can_do_unicode in
        0)
            PRCH=(
                sep "/" end ""
                retb "<" reta ">"
                circle "*" branch "\`|"
                ok ">" ellipsis ".."
                eol "~~" running ">"
            )
            ;|
        1|2)
            PRCH=(
                sep $'\uE0B1' end $'\uE0B0'
                retb "" reta $' \u2717'
                circle $'\u25CF' branch $'\uE0A0'
                ok $'\u2713' ellipsis $'\u2026'
                eol $'\u23CE' running $'\u276d'
            )
            ;|
        0|1)
            PRCH=(
                "${(@kv)PRCH}"
                elapsed ''
                python "python"
                docker "docker"
                envrc "envrc"
                nix "nix"
                completion ""
            )
            ;|
        2)
            PRCH=(
                "${(@kv)PRCH}"
                elapsed $'\u231b'
                python $'\U1f40d'
                docker $'\U1f40b'
                envrc $'\U1f343'
                nix $'\U1f578'
                completion $'\U1faa7'
            )
            ;|
    esac
}

 # Setting up less colors
(( ${terminfo[colors]:-0} >= 8 )) && {
    export LESS_TERMCAP_mb=$'\E[1;31m'
    export LESS_TERMCAP_md=$'\E[1;38;5;74m'
    export LESS_TERMCAP_me=$'\E[0m'
    export LESS_TERMCAP_se=$'\E[0m'
    export LESS_TERMCAP_so=$'\E[1;3;246m'
    export LESS_TERMCAP_ue=$'\E[0m'
    export LESS_TERMCAP_us=$'\E[1;32m'
}
