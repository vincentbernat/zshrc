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
    workon ${@[-1]}
}

(( $+commands[virtualenv] )) && {
    export PIP_REQUIRE_VIRTUALENV=true
    VIRTUAL_ENV_DISABLE_PROMPT=1
    hash -d venvs=$WORKON_HOME

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

    # Docker stuff
    local setupuser="
if ! id $USER > /dev/null 2> /dev/null; then
  echo $(getent passwd $(id -u)) >> /etc/passwd
  echo $(getent group $(id -g)) >> /etc/group
  mkdir -p /etc/sudoers.d
  echo \"$USER ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/$USER
  chmod 0440 /etc/sudoers.d/$USER
  [ -x /usr/bin/sudo ] || {
    cp /bin/sh /usr/bin/_root
    chown root:$(id -gn) /usr/bin/_root
    chmod 4750 /usr/bin/_root
    cat <<'EOF' > /usr/bin/sudo
#!/bin/sh
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
exec /usr/bin/_root -c \"/usr/sbin/chroot --userspec=root / sh -c 'cd \"\$PWD\" ; \$*'\"
EOF
    chmod +x /usr/bin/sudo
  }
fi
"

    # Docker images
    [[ ${dimages[(r)$env]} == $env ]] && {
        local image=${env}
        local tmp=$(mktemp -d)
        <<EOF > $tmp/start
for SHELL in $SHELL /bin/bash /bin/sh; do
  [ ! -x \$SHELL ] || break
done
$setupuser
exec chroot --userspec=$USER / \
     env HOME=$HOME TERM=$TERM DOCKER_CHROOT_NAME=$env \
     sh -c "[ -d '\$PWD' ] && cd '\$PWD' ; exec \$SHELL -i -l"
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
        local id=$(docker inspect --format '{{.State.Pid}}' $env)

        # We need to mount $HOME inside the container, that's quite
        # hacky: we get the device we need to mount, we mount it
        # somewhere, then bind mount the home directory in the right
        # place. All this with elevated privileges. We also create our
        # user, with sudo rights. Most inspiration comes from here:
        #  http://blog.dehacked.net/lxc-getting-mounts-into-a-running-container/
        #
        # Also, from Docker 0.9, see:
        #  http://jpetazzo.github.io/2014/03/23/lxc-attach-nsinit-nsenter-docker-0-9/
        #  http://www.sebastien-han.fr/blog/2014/01/27/access-a-container-without-ssh/
        #
        # From Docker 1.3, see `docker exec'.
        #
        # So, this needs nsenter which needs a recent util-linux.
        local homemnt=${${(f)"$(df --output=target $HOME)"}[-1]}
        local homedev=$(readlink -f ${${(f)"$(df --output=source $HOME)"}[-1]})
        local enter=/tmp/nsenter-$RANDOM-$$-$UID
        sudo =nsenter -m -t $id -- /bin/sh -e <<EOF
if ! mountpoint $HOME > /dev/null 2>/dev/null; then
  tmp=\$(mktemp -d)
  mkdir -p ${HOME}
  [ -b /dev/home-directory ] || mknod /dev/home-directory b $(stat -c "0x%t 0x%T" ${homedev})
  mount -n /dev/home-directory \$tmp
  rm /dev/home-directory
  mount -n --bind \$tmp/${HOME#$homemnt} $HOME
  umount -n \$tmp 2> /dev/null
  rmdir \$tmp
fi

# Shell to use
for SHELL in $SHELL /bin/bash /bin/sh; do
  [ ! -x \$SHELL ] || break
done

$setupuser

# Setup a command to enter this environment
CMD="env HOME=$HOME TERM=$TERM DOCKER_CHROOT_NAME=$env \$SHELL -i -l"
echo exec chroot --userspec=$USER / \$CMD > $enter

EOF
        local ret=$?
        [[ $ret -eq 0 ]] && {
            sudo =nsenter -m -u -i -n -p -w$HOME -t $id -- /bin/sh $enter
            ret=$?
        }
        return $ret
    }

    function save() {
        local v
        for v ($@) {
            _saved_environment[$v]=${${(e):-\$$v}}
        }
    }

    function restore() {
        local v
        for v (${(k)_saved_environment}) {
            unset $v
            [[ -z ${_saved_environment[$v]} ]] || export $v=${_saved_environment[$v]}
        }
    }

    # If in another virtualenv, call deactivate
    (( $+functions[deactivate_node] )) && deactivate_node
    (( $+functions[deactivate] )) && {
	deactivate
        restore
    }

    # Virtualenv
    [[ ${venv[(r)$env]} == $env ]] && {
	local activate="$WORKON_HOME/$env/bin/activate"
	local VIRTUAL_ENV_DISABLE_PROMPT=1
	local NODE_VIRTUAL_ENV_DISABLE_PROMPT=1
	source $activate

        typeset -Ag _saved_environment

        # Gems.
        # GEM_HOME is where gems will be installed.
        # GEM_PATH is where gems are searched
        save GEM_HOME GEM_PATH
        export GEM_HOME=$VIRTUAL_ENV/gems
        export GEM_PATH=$GEM_HOME
        path=( $GEM_HOME/bin $path )

        # Go
        save GOPATH
        export GOPATH=$VIRTUAL_ENV/go
        path=( $GOPATH/bin $path)

        # C (install with ./configure --prefix=$VIRTUAL_ENV)
        save LD_LIBRARY_PATH PKG_CONFIG_PATH
        export LD_LIBRARY_PATH=$VIRTUAL_ENV/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
        export PKG_CONFIG_PATH=$VIRTUAL_ENV/lib/pkgconfig
        path=( $VIRTUAL_ENV/sbin $path )

        # OCaml (through OPAM)
        (( $+commands[opam] )) && {
            save OPAMROOT MANPATH PERL5LIB CAML_LD_LIBRARY_PATH OCAML_TOPLEVEL_PATH
            export OPAMROOT=$VIRTUAL_ENV/opam
            [[ -d $OPAMROOT ]] && \
                eval $(opam config env)
        }

        # node.js workaround
        [[ -z $NPM_CONFIG_PREFIX ]] || {
            save npm_config_prefix
            export npm_config_prefix=$NPM_CONFIG_PREFIX
        }

        rehash
        return
    }

    [[ $env == "-" ]] || {
        print "ERROR: environment $env does not exist"
        return 2
    }
}
