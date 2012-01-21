# -*- sh -*-

# Include schroot name in prompt if available
[[ ! -f /etc/debian_chroot ]] || \
    SCHROOT_CHROOT_NAME=$(</etc/debian_chroot)
[[ -z $SCHROOT_CHROOT_NAME ]] || {
    _vbe_add_prompt_schroot () {
	print -n '${PR_BLUE}(${PR_YELLOW}sch:${PR_NO_COLOUR}${SCHROOT_CHROOT_NAME}${PR_BLUE})'
	print -n '$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT'
    }
}
