# -*- sh -*-

# Use emacs keybindings
bindkey -e

setopt interactivecomments	# Allow comments inside commands
setopt autopushd		# Maintain directories in a heap
setopt autocd			# Don't need to use `cd`

# meta-h will invoke man for the current command
autoload run-help

# No timeout
unset TMOUT
