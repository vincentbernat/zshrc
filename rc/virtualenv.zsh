# -*- sh -*-

# Virtualenv related functions
# Simplified version of virtualenvwrapper. Also works with nodeenv.
#  1. virtualenv works inside WORKON_HOME
#  2. workon allows to :
#       - switch to another environment
#       - deactivate an environment
#       - list available environments

(( $+commands[virtualenv] )) || (( $+commands[nodeenv] )) && {
    WORKON_HOME=${WORKON_HOME:-~/.virtualenvs}
    [[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME

    (( $+commands[virtualenv] )) && virtualenv () {
	pushd $WORKON_HOME > /dev/null && {
	    command virtualenv "$@"
	    popd > /dev/null
	}
    }

    (( $+commands[nodeenv] )) && nodeenv () {
	pushd $WORKON_HOME > /dev/null && {
	    command nodeenv "$@"
	    popd > /dev/null
	}
    }

    workon () {
	local env=$1
	# No parameters, list available environment
	[[ -n $env ]] || {
	    print "INFO: List of available environments:"
	    for env in $WORKON_HOME/*/bin/activate(.N:h:h:f); do
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
	}
	(( $+functions[deactivate_node] )) && {
	    deactivate_node
	}
	[[ $env == "-" ]] || {
	    local VIRTUAL_ENV_DISABLE_PROMPT=1
	    local NODE_VIRTUAL_ENV_DISABLE_PROMPT=1
	    source $activate
	}
	rehash
    }

    export PIP_REQUIRE_VIRTUALENV=true

    _vbe_add_prompt_virtualenv () {
        _vbe_prompt_env 've' '${VIRTUAL_ENV##*/}'
        _vbe_prompt_env 'nve' '${NODE_VIRTUAL_ENV##*/}'
    }

}
