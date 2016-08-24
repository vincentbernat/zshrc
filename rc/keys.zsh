# -*- sh -*-

# Use emacs keybindings
bindkey -e

# Some systems misses the appropriate /etc/inputrc for this
bindkey "\e[3~" delete-char        # Delete

# Replace insert-last-word by a smart version
autoload -U smart-insert-last-word
zle -N insert-last-word smart-insert-last-word
zstyle :insert-last-word match '(*[[:digit:]][.:][[:digit:]]*|*[[:alpha:]/\\]*)'

# Also copy previous word
autoload -U copy-earlier-word
zle -N copy-earlier-word
bindkey "\e," copy-earlier-word

# Meta-S will toggle sudo
function vbe-sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
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

