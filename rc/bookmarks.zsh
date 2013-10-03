# -*- sh -*-

# Handle bookmarks. Similar to jump in oh-my-zsh:
#  https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/jump/jump.plugin.zsh

MARKPATH=$ZSH/run/marks

g() {
    # cd to the right mark. `-P` is to avoid zsh to hide the real directory.
    cd -P $MARKPATH/$1
}

bookmark() {
    if (( $# == 0 )); then
        # Display bookmarks
        for link in $MARKPATH/*(@); do
            local markname="$fg[green]${link:t}$reset_color"
            local markpath="$fg[blue]${link:A}$reset_color"
            printf "%20s\t-> %s\n" $markname $markpath
        done
    else
        # Bookmark using the first argument as name
        [[ -d $MARKPATH ]] || mkdir -p $MARKPATH
        ln -s $PWD $MARKPATH/$1
    fi
}

_g() {
    local expl
    local -a results
    _path_files -/ -W $MARKPATH
}

compdef _g g
