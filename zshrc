# -*- sh -*-

# Use /bin/sh when no terminal is present
[[ ${TERM:-dumb} != "dumb" ]] || exec /bin/sh
[ -t 1 ] || exec /bin/sh

ZSH=${ZDOTDIR:-$HOME}/.zsh
fpath=($ZSH/functions $ZSH/completions $fpath)

# Autoload add-zsh-hook if available
autoload -U is-at-least
is-at-least 4.3.4 && autoload -U add-zsh-hook

for config_file ($ZSH/rc/*.zsh) source $config_file
for plugin ($plugins) source $ZSH/plugins/$plugin.plugin.zsh
unset config_file
unset plugin

_vbe_setprompt
