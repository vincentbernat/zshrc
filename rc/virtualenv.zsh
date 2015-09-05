# -*- sh -*-

# Virtualenv related functions
# Simplified version of virtualenvwrapper.

# Also setup the environment for Ruby gems.

WORKON_HOME=${WORKON_HOME:-~/.virtualenvs}

(( $+commands[virtualenv] )) && virtualenv () {
    [[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME
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

autoload -Uz workon
