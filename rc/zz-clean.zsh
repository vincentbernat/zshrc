# -*- sh -*-

# Remove old run files
rm -f $ZSH/run/{history,editor,zcompdump,editor,bookmarks}-*(NU.mw+10)

# Clean files in tmp
[ -d ~/tmp ] && {
    rm -f ~/tmp/**/*(U.mw+3)
    rmdir ~/tmp/**/*(U/mw+3)
}  2> /dev/null
