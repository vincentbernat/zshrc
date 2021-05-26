# -*- sh -*-
# Code from Mikael Magnusson: http://www.zsh.org/mla/users/2011/msg00367.html
#
# Requires xterm, urxvt, iTerm2 or any other terminal that supports
# bracketed paste mode as documented: http://www.xfree86.org/current/ctlseqs.html.
#
# This is enabled by default in Zsh 5.1+.
#
# By default, tmux doesn't paste using this mode. It's possible to
# force it to do so:
#
#    bind ] paste-buffer -p

(( $+zle_bracketed_paste == 0 )) \
    && [[  $TERM =~ ^(rxvt-unicode|xterm|screen)(-256color|-direct)?$ ]] \
    && () {

    # create a new keymap to use while pasting
    bindkey -N paste
    bindkey -R -M paste "^@"-"\M-^?" paste-insert
    bindkey '^[[200~' _start_paste
    bindkey -M paste '^[[201~' _end_paste
    bindkey -M paste -s '^M' '^J'

    zle -N _start_paste
    zle -N _end_paste
    zle -N paste-insert _paste_insert

    # switch the active keymap to paste mode
    function _start_paste() {
        bindkey -A paste main
    }

    # go back to our normal keymap, and insert all the pasted text in the
    # command line. this has the nice effect of making the whole paste be
    # a single undo/redo event.
    function _end_paste() {
        bindkey -e
        LBUFFER+=$_paste_content
        unset _paste_content
    }

    function _paste_insert() {
        _paste_content+=$KEYS
    }

    zle_bracketed_paste=( $'\C-[[?2004h' $'\C-[[?2004l' )
}
