# -*- sh -*-

# Use /bin/sh when no terminal is present
[[ ${TERM:-dumb} != "dumb" ]] || exec /bin/sh
[ -t 1 ] || exec /bin/sh

ZSH=${ZDOTDIR:-$HOME}/.zsh
fpath=($ZSH/functions $ZSH/completions $fpath)

for config_file ($ZSH/rc/*.zsh) source $config_file
for plugin ($plugins) source $ZSH/plugins/$plugin.plugin.zsh

_vbe_setprompt
