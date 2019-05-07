# -*- sh -*-

# Create $ZSH/run/u if it doesn't exist
[[ -d $ZSH/run/u ]] || {
    mkdir -p $ZSH/run/u
    chmod 1777 $ZSH/run/u
}

# Create per-UID directory
[[ -d $ZSH/run/u/$HOST-$UID ]] || {
    mkdir -p $ZSH/run/u/$HOST-$UID
}
