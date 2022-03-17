# -*- sh -*-

autoload -Uz is-at-least
autoload -Uz add-zsh-hook
autoload -Uz add-zle-hook-widget

[[ $ZSH_NAME == "zsh-static" ]] && is-at-least 5.4.1 && {
    # Don't tell us when modules are not available
    alias zmodload='zmodload -s'
}

zmodload -F zsh/stat b:zstat
zmodload zsh/datetime           # EPOCHSECONDS

source $ZSH/third-party/zsh-defer.zsh
