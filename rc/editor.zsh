# -*- sh -*-

# Setup EDITOR
() {
    local -a editors
    local editor
    editors=(
	"emacs -nw ${(%):-%(!.-q.)} --eval='(global-font-lock-mode 1) (setq make-backup-files nil)'" # emacs
        "mg -n"           # emacs clone (make it not create backup files)
        "jove"            # Another emacs clone (don't create backup files by default)
	"vim" "vi"	  # vi
	"editor")	  # fallback
    for editor in $editors; do
	(( $+commands[$editor[(w)1]] )) && {
	    # Some programs may not like to have arguments
	    if [[ $editor == *\ * ]]; then
		export EDITOR=$ZSH/run/u/$HOST-$UID/editor
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
            for editor in "emacsclient.${editor[(w)1]}" "emacsclient"; do
                (( $+commands[$editor] )) && break
            done
            export EDITOR=$ZSH/run/u/$HOST-$UID/editor-ec
            cat <<EOF > $EDITOR
#!/bin/sh
case \$DISPLAY in
  "") $editor -t -c "\$@" ;;
  *) $editor "\$@" ;;
esac
EOF
            chmod +x $EDITOR
	    alias e="$editor "'${=${DISPLAY:+-n}:--t -c}'
        }
    }

}

unset VISUAL
