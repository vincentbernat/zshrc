# -*- sh -*-

# Incorporate git information into prompt

[[ $USERNAME != "root" ]] && [[ $ZSH_NAME != "zsh-static" ]] && {

    # Async helpers
    _vbe_vcs_async_start() {
        async_start_worker vcs_info
        async_register_callback vcs_info _vbe_vcs_info_done
    }
    _vbe_vcs_info() {
        cd -q $1
        vcs_info
        print ${vcs_info_msg_0_}
    }
    _vbe_vcs_info_done() {
        local job=$1
        local return_code=$2
        local stdout=$3
        local more=$6
        case $job:$return_code in
            '[async]:2')
                # Need to restart the worker. Stolen from
                # https://github.com/mengelbrecht/slimline/blob/master/lib/async.zsh
                _vbe_vcs_async_start
                return
                ;;
        esac
        vcs_info_msg_0_=$stdout
        [[ $more == 1 ]] || zle reset-prompt
    }

    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    () {
        local formats="${PRCH[branch]} %b%c%u"
        local actionformats="${formats}%{${fg[default]}%} ${PRCH[sep]} %{${fg[green]}%}%a"
        zstyle    ':vcs_info:*:*' formats           $formats
        zstyle    ':vcs_info:*:*' actionformats     $actionformats
        zstyle    ':vcs_info:*:*' stagedstr         "%{${fg[green]}%}${PRCH[circle]}"
        zstyle    ':vcs_info:*:*' unstagedstr       "%{${fg[yellow]}%}${PRCH[circle]}"
	zstyle    ':vcs_info:*:*' check-for-changes true

        zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

        +vi-git-untracked(){
            if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
                git status --porcelain 2> /dev/null | grep -q '??' ; then
                hook_com[staged]+="%{${fg[black]}%}${PRCH[circle]}"
            fi
        }

    }

    # Asynchronous VCS status
    source $ZSH/third-party/async.zsh
    async_init
    _vbe_vcs_async_start
    add-zsh-hook precmd (){
        async_job vcs_info _vbe_vcs_info $PWD
    }
    add-zsh-hook chpwd (){
        vcs_info_msg_0_=
    }

    # Add VCS information to the prompt
    _vbe_add_prompt_vcs () {
	_vbe_prompt_segment cyan default ${vcs_info_msg_0_}
    }
}
