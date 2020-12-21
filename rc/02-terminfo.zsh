# -*- sh -*-

# Compute a sensible TERM and set colors
autoload -U zsh/terminfo zsh/termcap
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


typeset -gA PRCH
if _vbe_can_do_unicode; then
    PRCH=(
        sep $'\uE0B1' end $'\uE0B0'
        retb "" reta $' \u21B5'
        circle $'\u25CF' branch $'\uE0A0'
        ok $'\u2714' ellipsis $'\u2026'
        eol $'\u23CE' running $'\u21BB'
    )
else
    PRCH=(
        sep "/" end ""
        retb "<" reta ">"
        circle "*" branch "\`|"
        ok ">" ellipsis ".."
        eol "~~" running "> "
    )
fi

# Freeze the terminal
ttyctl -f
