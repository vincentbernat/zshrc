# -*- sh -*-

# Use emacs keybindings
bindkey -e

# Some systems misses the appropriate /etc/inputrc for this
bindkey "\e[3~" delete-char        # Delete

# Replace insert-last-word by a smart version
autoload smart-insert-last-word
zle -N insert-last-word smart-insert-last-word
zstyle :insert-last-word match '*([[:digit:]][.:][[:digit:]]|[[:digit:]][[:digit:]][[:digit:]]|[[:alpha:]/\\])*'

# Also copy previous word
autoload copy-earlier-word
zle -N copy-earlier-word
bindkey "\e," copy-earlier-word

# Enable magic quoting of URL
autoload url-quote-magic
zle -N self-insert url-quote-magic
autoload bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# Edit line in editor
autoload edit-command-line
zle -N edit-command-line
bindkey "^x^e" edit-command-line

# Meta-S will toggle sudo
function vbe-sudo-command-line() {
  [[ -z $BUFFER ]] && zle up-history
  case $BUFFER in
    sudoedit\ *)
        LBUFFER="e${LBUFFER#sudoedit}"
        ;;
    sudo\ *)
        LBUFFER="${LBUFFER#sudo }"
        ;;
    e\ *|e)
        LBUFFER="sudoedit${LBUFFER#e}"
        ;;
    *)
        LBUFFER="sudo $LBUFFER"
  esac
}
zle -N vbe-sudo-command-line
bindkey "\es" vbe-sudo-command-line

# Expand ... to ../..
function vbe-expand-dot-to-parent-directory-path() {
  case $LBUFFER in
    (./..|* ./..) LBUFFER+='.' ;; # In Go: "go list ./..."
    (..|*[ /=]..) LBUFFER+='/..' ;;
    (*) LBUFFER+='.' ;;
  esac
}
zle -N vbe-expand-dot-to-parent-directory-path
bindkey "." vbe-expand-dot-to-parent-directory-path
bindkey -M isearch "." self-insert

# Don't do history completion on empty words
function vbe-history-complete-older() {
  [[ ${LBUFFER[-1]} == ' ' || ${LBUFFER} == '' ]] && return 1
  zle _history-complete-older "$@"
}
zle -N vbe-history-complete-older
bindkey "\e/" vbe-history-complete-older
