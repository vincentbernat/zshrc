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

# In pbuilderrc, add:
#   export PBUILDERPID=$$
[[ -z $PBUILDERPID ]] || {
    _vbe_add_prompt_pbuilder () {
	print -n '${PR_BLUE}(${PR_YELLOW}pb:${PR_NO_COLOUR}${PBUILDERPID}${PR_BLUE})'
	print -n '$PR_CYAN$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT'
    }
}

# Here is the whole snippet that I am using:

# if [ "x$PBCURRENTCOMMANDLINEOPERATION" = xlogin ]; then
#   export PBUILDERPID=$$
#   [ -z $SUDO_UID ] || {
#     home=$(getent passwd $SUDO_UID | awk -F: '{print $6}')
#     BINDMOUNTS="$BINDMOUNTS $home"
#     export ZDOTDIR=$home
#   }
# fi

# Once inside pbuilder, I just do:
#  apt-get install zsh
#  exec zsh
