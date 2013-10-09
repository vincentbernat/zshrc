# -*- sh -*-

# Handle bookmarks. This uses the dynamic named directories feature of
# zsh. When you refer to ~[...] during a file expansion, the `...` is
# proposed to some function to be resolved. This is like tilde
# expansion but you can plug the resolution in a function. This also
# works to resolve a directory name to a shorten name.
#
# So, we can jump to a bookmark with `cd ~[@bookmark]`. Prompt
# expansion is also aware of those bookmarks. The prompt should show
# the bookmark name. And we get completion.
#
# With autocd, you can just type `~[@bookmark]`. Since this can be
# cumbersome to type, you can also type `@@` and this will be turned
# into `~[@` by ZLE.

MARKPATH=$ZSH/run/marks

_bookmark_directory_name() {
    emulate -L zsh
    setopt extendedglob
    case $1 in
        d)
            # Turn the directory into a shortest name using
            # bookmarks. We need to sort them by length of solved
            # path.
            local link
            local -a links
            for link in $MARKPATH/*(N@); do
                links+=(${#link:A}$'\0'$link)
            done
            links=("${(@)${(@On)links}#*$'\0'}")
            for link in $links; do
                if [[ $2 = (#b)(${link:A})(|/*) ]]; then
                    typeset -ga reply
                    reply=("@"${link:t} $(( ${#match[1]} )) )
                    return 0
                fi
            done
            return 1
            ;;
        n)
            # Turn the name into a directory
            [[ $2 != (#b)"@"(?*) ]] && return 1
            typeset -ga reply
            reply=(${${:-$MARKPATH/$match[1]}:A})
            return 0
            ;;
        c)
            # Completion
            local expl
            local -a dirs
            dirs=($MARKPATH/*(N@:t))
            dirs=("@"${^dirs})
            _wanted dynamic-dirs expl 'bookmarked directory' compadd -S\] -a dirs
            return
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook zsh_directory_name _bookmark_directory_name
else
    zsh_directory_name () {
	_bookmark_directory_name
    }
fi

vbe-insert-bookmark() {
    emulate -L zsh
    LBUFFER=${LBUFFER}"~[@"
}
zle -N vbe-insert-bookmark
bindkey '@@' vbe-insert-bookmark

# Manage bookmarks
bookmark() {
    [[ -d $MARKPATH ]] || mkdir -p $MARKPATH
    if (( $# == 0 )); then
        # Display bookmarks
        for link in $MARKPATH/*(N@); do
            local markname="$fg[green]${link:t}$reset_color"
            local markpath="$fg[blue]${link:A}$reset_color"
            printf "%-30s -> %s\n" $markname $markpath
        done
    else
        local -a delete
        zparseopts -D d=delete
        if (( $+delete[1] )); then
            # Delete bookmark
            command rm $MARKPATH/$1
        else
            # Add bookmark
            ln -s $PWD $MARKPATH/$1
        fi
    fi
}
