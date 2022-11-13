# -*- sh -*-

# Setup EDITOR
() {
    unset EDITOR ALTERNATE_EDITOR
    local -a editors
    local editor
    editors=(
	"emacs -nw ${(%):-%(!.-q.)} --eval='(progn (global-font-lock-mode 1) (setq make-backup-files nil))'" # emacs
    "mg -n"         # emacs clone (make it not create backup files)
    "jove"          # Another emacs clone (don't create backup files by default)
	"vim" "vi"      # vi
	"editor")       # fallback
    for editor in $editors; do
	(( $+commands[$editor[(w)1]] )) && {
	    # Some programs may not like to have arguments
	    if [[ $editor == *\ * ]]; then
		export EDITOR=$ZSHRUN/editor
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
        (( $+commands[sudo] == 1 && $+commands[sudoedit] == 0 )) && \
            alias sudoedit='sudo $EDITOR'
        # Maybe use emacsclient?
        [[ $editor == emacs* ]] && (( $+commands[emacsclient] )) && {
	    export ALTERNATE_EDITOR=$EDITOR
            export EDITOR=$ZSHRUN/editor-ec
            cat <<'EOF' > $EDITOR.$$
#!/bin/sh
case $DISPLAY in
  "") exec emacsclient -q -t -c "$@" ;;
  *) exec emacsclient -q "$@" ;;
esac
EOF
            chmod +x $EDITOR.$$
            mv -f $EDITOR.$$ $EDITOR
            alias e="$EDITOR ${DISPLAY:+-n}"
        }
    }

}

unset VISUAL
