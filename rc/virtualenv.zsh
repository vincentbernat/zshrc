# -*- sh -*-

# Virtualenv related functions
# Simplified version of virtualenvwrapper.
#  1. virtualenv works inside WORKON_HOME
#  2. workon allows to :
#       - switch to another environment
#       - deactivate an environment
#       - list available environments

# To reuse the environment for Node.JS, use:
#  $ pip install nodeenv
#  $ nodeenv -p -n system

# Also setup the environment for Ruby gems.

# The workon command can also be used to get inside a docker
# environment. In this case, it will arrange for sudo to work without
# a password, mount /home and place yourself in an appropriate
# directory.

WORKON_HOME=${WORKON_HOME:-~/.virtualenvs}
[[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME

(( $+commands[virtualenv] )) && virtualenv () {
    pushd $WORKON_HOME > /dev/null && {
	command virtualenv "$@"
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

    # No parameters, list available environment
    [[ -n $env ]] || {
	print "INFO: List of available environments:"
	for env in $WORKON_HOME/*/bin/activate(.N:h:h:ft); do
	    print " - [virtualenv] $env"
	done
        for image in $(docker images | awk '(NR > 1){printf("%s\\:%s\n", $1,$2)}'); do
            print " - [docker    ] docker@$image"
        done
	return 0
    }

    # Docker
    [[ $env == docker@* ]] && {
        local image=${env#docker@}
        local tmp=$(mktemp -d)
        <<EOF > $tmp/start
echo $(getent passwd $(id -u)) >> /etc/passwd
echo $(getent group $(id -g)) >> /etc/group
echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER
chmod 0440 /etc/sudoers.d/$USER
exec sudo -u $USER env HOME=$HOME $SHELL -i -l
EOF
        docker run -t -i \
            -v $HOME:$HOME \
            -v $tmp:$tmp \
            -w $PWD \
            -u root \
            -h ${${image##*/}:gs/:/-} \
            -entrypoint /bin/sh \
            $image $tmp/start
        rm -f $tmp/start && rmdir $tmp
    }

    # If in another virtualenv, call deactivate
    (( $+functions[deactivate] )) && {
	deactivate
        [[ -z $_OLD_GEM_HOME ]] || export GEM_HOME=$_OLD_GEM_HOME
        [[ -z $_OLD_GEM_PATH ]] || export GEM_PATH=$_OLD_GEM_PATH
    }

    # If in another dockerenv, exit
    [[ -n $DOCKERENV ]] && exit 0

    # Otherwise, switch to the environment
    [[ $env != "-" ]] && [[ $env != docker@* ]] && {
	local activate
	activate="$WORKON_HOME/$env/bin/activate"
	[[ -d $WORKON_HOME/$env ]] || {
	    print "ERROR: environment $env does not exist"
	    return 2
	}
	[[ -f $activate ]] || {
	    print "ERROR: environment $env does not have activate script"
	    return 1
	}

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
    }
    rehash
}
