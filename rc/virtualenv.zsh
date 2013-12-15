# -*- sh -*-

# Virtualenv related functions
# Simplified version of virtualenvwrapper.
#  1. virtualenv works inside WORKON_HOME
#  2. workon allows to :
#       - switch to another environment
#       - deactivate an environment
#       - list available environments

# For nodeenv, use:
#  $ pip install nodeenv
#  $ nodeenv -p -n system

# Also setup the environment for gems.

(( $+commands[virtualenv] )) && {
    WORKON_HOME=${WORKON_HOME:-~/.virtualenvs}
    [[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME

    (( $+commands[virtualenv] )) && virtualenv () {
	pushd $WORKON_HOME > /dev/null && {
	    command virtualenv "$@"
	    popd > /dev/null
	}
        workon $(_vbe_first_non_optional_arg "$@")
    }

    workon () {
	local env=$1
	# No parameters, list available environment
	[[ -n $env ]] || {
	    print "INFO: List of available environments:"
	    for env in $WORKON_HOME/*/bin/activate(.N:h:h:ft); do
		print " - $env"
	    done
	    return 0
	}
	# Otherwise, switch to the environment
	[[ $env == "-" ]] || {
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
	}
	# If in another environment, call deactivate
	(( $+functions[deactivate] )) && {
	    deactivate
            [[ -z $_OLD_GEM_HOME ]] || export GEM_HOME=$_OLD_GEM_HOME
            [[ -z $_OLD_GEM_PATH ]] || export GEM_PATH=$_OLD_GEM_PATH
	}
	[[ $env == "-" ]] || {
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

    export PIP_REQUIRE_VIRTUALENV=true

    _vbe_add_prompt_virtualenv () {
        _vbe_prompt_env 've' '${VIRTUAL_ENV##*/}'
    }

}
