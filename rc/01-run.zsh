# -*- sh -*-

# Create $ZSH/run/u if it doesn't exist
[[ -d $ZSH/run/u ]] || {
    mkdir -p $ZSH/run/u
    chmod 1777 $ZSH/run/u
}

# Create per-UID directory and do migration
[[ -d $ZSH/run/u/$HOST/$UID ]] || {
    mkdir -p $ZSH/run/u/$HOST/$UID
    for f in $ZSH/run/{acpi,history,editor,zcompdump,bookmarks}-$HOST-$UID(N); do
        mv $f $ZSH/run/u/$HOST/$UID/${${f##*/}%-$HOST-$UID}
    done
    for f in $ZSH/run/u/$UID/{acpi,history,editor,zcompdump,bookmarks}-$HOST(N); do
        mv $f $ZSH/run/u/$HOST/$UID/${${f##*/}%-$HOST}
    done
    rmdir $ZSH/run/u/$UID 2> /dev/null
}
