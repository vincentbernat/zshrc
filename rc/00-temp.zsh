# -*- sh -*-

# Safe creation of temporary directory
[ ! -d ~/tmp ] && {
    rm ~/tmp 2> /dev/null
    ln -s $(mktemp -d) ~/tmp
}
