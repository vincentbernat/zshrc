# -*- sh -*-

# Safe creation of temporary directory
[ -h ~/tmp ] && [ ! -d ~/tmp ] && {
    rm ~/tmp 2> /dev/null
    ln -s $(mktemp -d) ~/tmp
}
