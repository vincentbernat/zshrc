# -*- sh -*-

setopt rmstarsilent             # Don't ask for confirmation on rm *
setopt interactivecomments	# Allow comments inside commands
setopt autopushd		# Maintain directories in a heap
setopt pushdignoredups          # Remove duplicates from directory heap
setopt pushdminus               # Invert + and - meanings
setopt autocd			# Don't need to use `cd`
setopt longlistjobs             # Display PID when using jobs
setopt nobeep                   # Never beep
setopt nocorrect nocorrectall   # Disable autocorrect
setopt noflowcontrol            # Disable flow control for Zsh

# meta-h will invoke man for the current command
(( ${+aliases[run-help]} )) && unalias run-help
autoload -Uz run-help
() {
    local c
    for c in sudo git openssl ip nix; do
        (( $+commands[$c] )) && autoload -Uz run-help-$c
    done
}

# Remove / and # from WORDCHARS
WORDCHARS=${${WORDCHARS:s#/#}:s,#,}

if (( ${termcap[Co]:-0} > 8)); then
    # Enable and configure autosuggest
    zsh-defer source $ZSH/third-party/zsh-autosuggestions.zsh
    typeset -g ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
    ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
        insert-last-word
    )
    function _vbe-reset-autosuggest() {
        zle autosuggest-clear
        zle autosuggest-fetch
    }
else
    function _vbe-reset-autosuggest() {}
fi
zle -N _vbe-reset-autosuggest
