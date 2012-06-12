# -*- sh -*-

# Setup EDITOR
__() {
    local -a editors
    local editor
    editors=(
	"emacs -Q -D -nw" # Fast emacs
	"emacs23 -Q -D -nw" # Fast emacs
	"emacs22 -Q -D -nw" # Fast emacs
	"jove" "mg" "jed" # Emacs clone
	"vim" "vi"	  # vi
	"editor")	  # fallback
    for editor in $editors; do
	(( $+commands[$editor[(w)1]] )) && {
	    # Some programs may not like to have arguments
	    if [[ $editor == *\ * ]]; then
		export EDITOR=$ZSH/run/editor-$HOST-$UID
		cat <<EOF > $EDITOR
#!/bin/sh
exec $editor "\$@"
EOF
		chmod +x $EDITOR
	    else
		export EDITOR=$editor
	    fi
	    break
	}
    done
} && __

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
