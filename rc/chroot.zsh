# -*- sh -*-

_vbe_prompt_env () {
    local kind=$1
    local name=${(e)${2}}
    [[ -z $name ]] || {
        _vbe_prompt_segment blue black $kind
        _vbe_prompt_segment blue black $name
    }
}

# Are we running inside lxc? lxc sets `container` environment variable
# for PID 1 but this seems difficult to get as a simple
# user. Therefore, we will look at /proc/self/cgroup.
[[ -z $DOCKER_CHROOT_NAME ]] && [[ -f /proc/self/cgroup ]] && {
    autoload -U zsh/regex
    case $(</proc/self/cgroup) in
        *:/lxc/*)
            LXC_CHROOT_NAME=${${(s:/:)${${(s: :)$(</proc/self/cgroup)}[(rw)*:/lxc/*]}}[-1]}
            # Maybe, it's a docker container, keep only 12 characters in this case
            if [[ $LXC_CHROOT_NAME -regex-match [0-9a-f]{64} ]]; then
                DOCKER_CHROOT_NAME=${LXC_CHROOT_NAME[1,12]}
                unset LXC_CHROOT_NAME
            fi
            ;;
        *:/docker/*)
            DOCKER_CHROOT_NAME=${${${(s:/:)${${(s: :)$(</proc/self/cgroup)}[(rw)*:/docker/*]}}[-1]}[1,12]}
            ;;
        */docker-*)
            DOCKER_CHROOT_NAME=${${${(s:-:)${${(s: :)$(</proc/self/cgroup)}[(rw)*/docker-*]}}[-1]}[1,12]}
            ;;
    esac
}
[[ -z $LXC_CHROOT_NAME ]] || {
    _vbe_add_prompt_lxc () {
        _vbe_prompt_env 'lxc' '${LXC_CHROOT_NAME}'
    }
}
[[ -z $DOCKER_CHROOT_NAME ]] || {
    _vbe_add_prompt_docker () {
        _vbe_prompt_env 'docker' '${DOCKER_CHROOT_NAME}'
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

# In netns
(( $+commands[ip] )) && [[ x"$(ip netns identify 2> /dev/null)" != x ]] && {
    _vbe_add_prompt_netns () {
        _vbe_prompt_env 'netns' "$(ip netns identify)"
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
