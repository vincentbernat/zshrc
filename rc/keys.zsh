# -*- sh -*-

# Use emacs keybindings
bindkey -e

# Some systems misses the appropriate /etc/inputrc for this
bindkey "\e[3~" delete-char        # Delete

# Replace insert-last-word by a smart version
autoload -Uz smart-insert-last-word
zle -N insert-last-word smart-insert-last-word
zstyle :insert-last-word match '*([[:digit:]][.:][[:digit:]]|[[:digit:]][[:digit:]][[:digit:]]|[[:alpha:]/\\])*'

# Also copy previous word
autoload -Uz copy-earlier-word
zle -N copy-earlier-word
bindkey "\e," copy-earlier-word

# Enable magic quoting of URL
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# Edit line in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^x^e" edit-command-line

# Meta-S will toggle sudo
function _vbe-sudo-command-line() {
  [[ -z $BUFFER ]] && zle up-history
  # We need to also make it work if cursor is inside the program name. In this
  # case, we manipulate BUFFER instead of LBUFFER.
  case $BUFFER in
    sudoedit\ *)
      case $LBUFFER in
        sudoedit*) LBUFFER=e${LBUFFER#sudoedit} ;;
        *) BUFFER=e${BUFFER#sudoedit}; CURSOR=$(( CURSOR - ${#${:-sudoedit}} + 1 )) ;;
      esac
      ;;
    sudo\ *)
      case $LBUFFER in
        sudo*) LBUFFER=${LBUFFER#sudo } ;;
        *) BUFFER=${BUFFER#sudo }; CURSOR=$(( CURSOR - ${#${:-sudo}} - 1 )) ;;
      esac
      ;;
    e\ *)
      case $LBUFFER in
        e*) LBUFFER="sudoedit ${LBUFFER#e }" ;;
        *) BUFFER="sudoedit ${BUFFER#e }"; CURSOR=$(( CURSOR + ${#${:-sudoedit}} - 1 )) ;;
      esac
      ;;
    *)
      local prog nprog
      prog=${${(Az)BUFFER}[1]}
      nprog=${${${${aliases[$prog]:-${prog}}#sudo }#command }#=}
      if [[ $prog == ${${(Az)LBUFFER}[1]} ]]; then
        LBUFFER="sudo =${LBUFFER/$prog/$nprog}"
      else
        BUFFER="sudo =${BUFFER/$prog/$nprog}"
        CURSOR=$(( CURSOR + ${#${:-sudo}} + 1 ))
      fi
      ;;
  esac
  zle _vbe-reset-autosuggest
}
zle -N _vbe-sudo-command-line
bindkey "\es" _vbe-sudo-command-line

# Expand ... to ../..
function _vbe-expand-dot-to-parent-directory-path() {
  case $LBUFFER in
    (./..|* ./..) LBUFFER+='.' ;; # In Go: "go list ./..."
    (..|*[ /=]..) LBUFFER+='/..' ;;
    (*) LBUFFER+='.' ;;
  esac
  zle _vbe-reset-autosuggest
}
zle -N _vbe-expand-dot-to-parent-directory-path
bindkey "." _vbe-expand-dot-to-parent-directory-path
bindkey -M isearch "." self-insert

# Don't do history completion on empty words
function _vbe-history-complete-older() {
  [[ ${LBUFFER[-1]} == ' ' || ${LBUFFER} == '' ]] && return 1
  zle _history-complete-older "$@"
}
zle -N _vbe-history-complete-older
bindkey "\e/" _vbe-history-complete-older
