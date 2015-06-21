# -*- sh -*-

# Create $ZSH/run/u/$UID if it doesn't exist
[[ -d $ZSH/run/u ]] || {
    mkdir -p $ZSH/run/u
    chmod 1777 $ZSH/run/u
}
[[ -d $ZSH/run/u/$UID ]] || mkdir -p $ZSH/run/u/$UID

# Migration of existing files in $ZSH/run
for f in $ZSH/run/{history,editor,zcompdump,bookmarks}-${(%):-%m}-$UID(N); do
    mv $f $ZSH/run/u/$UID/${${f##*/}%-$UID}
done
