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

(( $+zle_bracketed_paste == 0 )) && [[  $TERM == rxvt-unicode || \
    $TERM == rxvt-unicode-256color || \
    $TERM == xterm || \
    $TERM == xterm-256color || \
    $TERM == screen || \
    $TERM == screen-256color ]] && __() {

    # create a new keymap to use while pasting
    bindkey -N paste
    bindkey -R -M paste "^@"-"\M-^?" paste-insert
    bindkey '^[[200~' _start_paste
    bindkey -M paste '^[[201~' _end_paste
    bindkey -M paste -s '^M' '^J'

    zle -N _start_paste
    zle -N _end_paste
    zle -N zle-line-init _zle_line_init
    zle -N zle-line-finish _zle_line_finish
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

    function _zle_line_init() {
        # Tell terminal to send escape codes around pastes.
        printf '\e[?2004h'
    }

    function _zle_line_finish() {
        # Tell it to stop when we leave zle, so pasting in other programs
        # doesn't get the ^[[200~ codes around the pasted text.
        printf '\e[?2004l'
    }
} && __
