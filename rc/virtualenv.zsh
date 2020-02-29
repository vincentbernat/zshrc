# -*- sh -*-

# Virtualenv related functions
# Simplified version of virtualenvwrapper.

WORKON_HOME=${WORKON_HOME:-~/.virtualenvs}

(( $+commands[virtualenv] )) && {
    _virtualenv () {
        local interpreter
        case $1 in
            2) interpreter=python2 ;;
            3) interpreter=python3 ;;
            *) interpreter=python ;;
        esac
        shift
        [[ -d $WORKON_HOME ]] || mkdir -p $WORKON_HOME
        pushd $WORKON_HOME > /dev/null || return
	! command virtualenv -p =$interpreter "$@" || \
            cat <<EOF >&2
${fg[white]}
# To reuse the environment for Node.JS, use:
#  \$ pip install nodeenv
#  \$ nodeenv -p -n system

EOF
	popd > /dev/null || return
        workon ${@[-1]}
        [[ ${@[-1]} == "tmp" ]] && \
            rm -rf $WORKON_HOME/tmp
    }
    alias virtualenv2='_virtualenv 2'
    alias virtualenv3='_virtualenv 3'
    (( $+commands[python2] )) && alias virtualenv='_virtualenv 2'
    (( $+commands[python3] )) && alias virtualenv='_virtualenv 3'
}

(( $+commands[virtualenv] )) && {
    export PIP_REQUIRE_VIRTUALENV=true
    hash -d venvs=$WORKON_HOME

    _vbe_add_prompt_virtualenv () {
        _vbe_prompt_env 've' '${VIRTUAL_ENV##*/}'
    }
}

autoload -Uz workon
