# -*- sh -*-

# Remove old run files
rm -f $ZSH/run/u/*/{history,editor,zcompdump,editor,bookmarks}-*(NU.aw+10) 2> /dev/null

# Clean files in tmp
[ -d ~/tmp ] && {
    rm -f ~/tmp/**/*(NU.cw+3)
    rmdir ~/tmp/**/*(NU/cw+3^F)
}  2> /dev/null
