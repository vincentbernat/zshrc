# -*- sh -*-

_vbe_prompt_env () {
    local kind=$1
    local name=$2
    local -a p1
    p1=( '${' ${name} ':+'
	${kind} '|' ${name} '}')
    _vbe_prompt_segment blue black ${(e)${(j::)p1}}
}

# Are we running inside lxc? lxc sets `container` environment variable
# for PID 1 but this seems difficult to get as a simple
# user. Therefore, we will look at /proc/self/cgroup.
[[ ! -f /proc/self/cgroup ]] || {
    case $(</proc/self/cgroup) in
        *:/lxc/*)
            LXC_CHROOT_NAME=${$(</proc/self/cgroup)##*:/lxc/}
                ;;
    esac
}
[[ -z $LXC_CHROOT_NAME ]] || {
    _vbe_add_prompt_lxc () {
        _vbe_prompt_env 'lxc' '${LXC_CHROOT_NAME}'
    }
}

# Include schroot name in prompt if available
[[ ! -f /etc/debian_chroot ]] || [[ -n $LXC_CHROOT_NAME ]] || \
    SCHROOT_CHROOT_NAME=$(</etc/debian_chroot)
[[ -z $SCHROOT_CHROOT_NAME ]] || {
    _vbe_add_prompt_schroot () {
        _vbe_prompt_env 'sch' '${SCHROOT_CHROOT_NAME}'
    }
}

# In pbuilderrc, add:
#   export PBUILDERPID=$$
[[ -z $PBUILDERPID ]] || {
    _vbe_add_prompt_pbuilder () {
        _vbe_prompt_env 'pb' '${PBUILDERPID}'
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
