# -*- sh -*-

# Virtualenv related functions
# Simplified version of virtualenvwrapper.
#  1. virtualenv works inside WORKON_HOME
#  2. workon allows to :
#       - switch to another environment
#       - deactivate an environment
#       - list available environments

# Also setup the environment for Ruby gems.

# The workon command can also be used to get inside a docker
# environment. In this case, it will arrange for sudo to work without
# a password, mount /home and place yourself in an appropriate
# directory.

WORKON_HOME=${WORKON_HOME:-~/.virtualenvs}
[[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME

(( $+commands[virtualenv] )) && virtualenv () {
    pushd $WORKON_HOME > /dev/null && {
	command virtualenv "$@" && \
            cat <<EOF >&2
${fg[white]}
# To reuse the environment for Node.JS, use:
#  \$ pip install nodeenv
#  \$ nodeenv -p -n system

EOF
	popd > /dev/null
    }
    workon $(_vbe_first_non_optional_arg "$@")
}

(( $+commands[virtualenv] )) && {
    export PIP_REQUIRE_VIRTUALENV=true

    _vbe_add_prompt_virtualenv () {
        _vbe_prompt_env 've' '${VIRTUAL_ENV##*/}'
    }
}

(( $+commands[virtualenv] + $+commands[docker] )) && workon () {
    local env=$1
    local -a venv dimages dcontainers
    venv=($WORKON_HOME/*/bin/activate(.N:h:h:ft))
    (( $+commands[docker] )) && [[ -w /var/run/docker.sock ]] && {
        dimages=( $(docker images | awk '(NR > 1 && $1 !~ /^</){printf("%s:%s\n", $1,$2)}') )
        dcontainers=( $(docker ps | awk '(NR > 1){split($NF,names,/,/); for (i in names) printf("%s\n",names[i])}') )
    }

    # No parameters, list available environment
    [[ -n $env ]] || {
	print "INFO: List of available environments:"
	for env in $venv; do
	    print " - [virtualenv] $env"
	done
        for image in $dimages; do
            print " - [docker    ] $image"
        done
	return 0
    }

    [[ $env == "." ]] && env=${PWD:t}

    # Docker images
    [[ ${dimages[(r)$env]} == $env ]] && {
        local image=${env}
        local tmp=$(mktemp -d)
        <<EOF > $tmp/start
echo $(getent passwd $(id -u)) >> /etc/passwd
echo $(getent group $(id -g)) >> /etc/group
echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
chmod 0440 /etc/sudoers.d/$USER
exec sudo -u $USER env HOME=$HOME TERM=$TERM $SHELL -i -l
EOF
        docker run -t -i \
            -v $HOME:$HOME \
            -v $tmp:$tmp \
            -w $PWD \
            -u root \
            --rm \
            -h ${${${image##*/}:gs/:/-}:gs/./-} \
            --entrypoint /bin/sh \
            $image $tmp/start
        local ret=$?
        rm -f $tmp/start && rmdir $tmp
        return $ret
    }

    # Docker containers
    [[ ${dcontainers[(r)$env]} == $env ]] && {
        local id=$(docker ps --no-trunc | \
            awk -v env=$env \
            '(NR > 1){split($NF,names,/,/); for (i in names) if (names[i] == env) printf("%s",$1)}')

        # We need to mount $HOME inside the container, that's quite
        # hacky: we get the device we need to mount, we mount it
        # somewhere, then bind mount the home directory in the right
        # place. All this with elevated privileges. We also create our
        # user, with sudo rights. Most inspiration comes from here:
        #  http://blog.dehacked.net/lxc-getting-mounts-into-a-running-container/
        #
        # Also, from Docker 0.9, see:
        #  http://bindable.fr/make-lxc-attach-work-again-docker-09
        local homemnt=${${(f)"$(df --output=target $HOME)"}[-1]}
        local homedev=$(readlink -f ${${(f)"$(df --output=source $HOME)"}[-1]})
        sudo lxc-attach -s MOUNT -n $id -- /bin/sh -e <<EOF
if ! mountpoint $HOME > /dev/null 2>/dev/null; then
  tmp=\$(mktemp -d)
  mkdir -p ${HOME}
  [ -b /dev/home-directory ] || mknod /dev/home-directory b $(stat -c "0x%t 0x%T" ${homedev})
  mount /dev/home-directory \$tmp
  rm /dev/home-directory
  mount --bind \$tmp/${HOME#$homemnt} $HOME
  umount \$tmp
  rmdir \$tmp
fi

if ! id $USER > /dev/null 2> /dev/null; then
  echo $(getent passwd $(id -u)) >> /etc/passwd
  echo $(getent group $(id -g)) >> /etc/group
  echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
  chmod 0440 /etc/sudoers.d/$USER
fi
EOF
        local ret=$?
        [[ $ret -eq 0 ]] && {
            sudo lxc-attach -n $id -- sudo -u $USER env HOME=$HOME TERM=$TERM $SHELL -i -l
            ret=$?
        }
        return $ret
    }

    # If in another virtualenv, call deactivate
    (( $+functions[deactivate] )) && {
	deactivate
        [[ -z $_OLD_GEM_HOME ]] || export GEM_HOME=$_OLD_GEM_HOME
        [[ -z $_OLD_GEM_PATH ]] || export GEM_PATH=$_OLD_GEM_PATH
        [[ -z $_OLD_GOPATH ]]   || export GOPATH=$_OLD_GOPATH
        [[ -z $_OLD_LD_LIBRARY_PATH ]] || export LD_LIBRARY_PATH=$_OLD_LD_LIBRARY_PATH
        [[ -z $_OLD_PKG_CONFIG_PATH ]] || export PKG_CONFIG_PATH=$_OLD_PKG_CONFIG_PATH
    }

    # Virtualenv
    [[ ${venv[(r)$env]} == $env ]] && {
	local activate="$WORKON_HOME/$env/bin/activate"
	local VIRTUAL_ENV_DISABLE_PROMPT=1
	local NODE_VIRTUAL_ENV_DISABLE_PROMPT=1
	source $activate

        # Gems.
        # GEM_HOME is where gems will be installed.
        # GEM_PATH is where gems are searched
        _OLD_GEM_HOME=$GEM_HOME
        export GEM_HOME=$VIRTUAL_ENV/gems
        _OLD_GEM_PATH=$GEM_PATH
        export GEM_PATH=$GEM_HOME
        path=( $GEM_HOME/bin $path )

        # Go
        _OLD_GOPATH=$GOPATH
        export GOPATH=$VIRTUAL_ENV/go
        path=( $GOPATH/bin $path)

        # C (install with ./configure --prefix=$VIRTUAL_ENV/usr)
        _OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
        _OLD_PKG_CONFIG_PATH=$PKG_CONFIG_PATH
        export LD_LIBRARY_PATH=$VIRTUAL_ENV/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
        export PKG_CONFIG_PATH=$VIRTUAL_ENV/usr/lib/pkgconfig
        path=( $VIRTUAL_ENV/usr/bin $VIRTUAL_ENV/usr/sbin $path )

        rehash
        return
    }

    [[ $env == "-" ]] || {
        print "ERROR: environment $env does not exist"
        return 2
    }
}
