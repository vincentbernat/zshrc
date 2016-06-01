# -*- sh -*-

setopt rmstarsilent             # Don't ask for confirmation on rm *
setopt interactivecomments	# Allow comments inside commands
setopt autopushd		# Maintain directories in a heap
setopt autocd			# Don't need to use `cd`
setopt extendedglob             # Enable extended globbing
setopt longlistjobs             # Display PID when using jobs
setopt nobeep                   # Never beep

# meta-h will invoke man for the current command
autoload run-help
# When the command is {sudo,git,openssl} something, get help on something
autoload run-help-sudo
autoload run-help-git
autoload run-help-openssl
autoload run-help-ip

# Remove / from WORDCHARS (more like bash)
WORDCHARS=${WORDCHARS:s#/#}
