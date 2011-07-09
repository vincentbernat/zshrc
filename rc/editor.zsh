# -*- sh -*-

# Setup EDITOR
() {
    local -a editors
    editors=(
	"emacs -Q -D -nw" # Fast emacs
	"jove" "mg" "jed" # Emacs clone
	"vim" "vi"	  # vi
	"editor")	  # fallback
    for editor in $editors; do
	(( $+commands[$editor[(w)1]] )) && {
	    export EDITOR=$editor
	    break
	}
    done
}

[[ -z $EDITOR ]] || {
    alias e=$EDITOR
    # Maybe use emacsclient?
    (( $+commands[emacsclient] )) && {
	export ALTERNATE_EDITOR=$EDITOR
	export EDITOR="emacsclient"
	alias e="emacsclient -n"
    }
}

unset VISUAL
