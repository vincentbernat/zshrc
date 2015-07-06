# -*- sh -*-

# Setup EDITOR
__() {
    local -a editors
    local editor
    editors=(
	"emacs-snapshot -nw" # emacs
	"emacs24 -nw"     # emacs
	"emacs23 -nw"     # emacs
	"emacs22 -nw"     # emacs
	"zile"		  # Emacs clone
	"jove" "mg" "jed" # Emacs clone
	"vim" "vi"	  # vi
	"editor")	  # fallback
    for editor in $editors; do
	(( $+commands[$editor[(w)1]] )) && {
	    # Some programs may not like to have arguments
	    if [[ $editor == *\ * ]]; then
		export EDITOR=$ZSH/run/u/$HOST/$UID/editor
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
    [[ -z $EDITOR ]] || {
        alias e=$EDITOR
        # Maybe use emacsclient?
        [[ $editor == emacs* ]] && (( $+commands[emacsclient] )) && {
	    export ALTERNATE_EDITOR=$EDITOR
	    export EDITOR="emacsclient"
            local ecargs='${=${DISPLAY:+-n}:--t -c}'
	    alias e="emacsclient $ecargs"
        }
    }

} && __


unset VISUAL
