# -*- sh -*-

# Safe creation of temporary directory
([ -h ~/tmp ] || [ ! -d ~/tmp ]) && {
    rm -f ~/tmp 2> /dev/null
    mkdir ~/tmp
    # ln -s $(mktemp -d) ~/tmp
}
[ -d ~/tmp ] && {
    rm -f ~/tmp/**/*(U.mw+3)
    rmdir ~/tmp/**/*(U/mw+3)
}  2> /dev/null
