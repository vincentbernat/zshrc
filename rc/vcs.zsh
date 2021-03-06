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
        if [[ $job == '[async]' ]]; then
            if [[ $return_code -eq 2 ]]; then
                # Need to restart the worker. Stolen from
                # https://github.com/mengelbrecht/slimline/blob/master/lib/async.zsh
                _vbe_vcs_async_start
                return
            fi
        fi
        vcs_info_msg_0_=$stdout
        (( $more )) || zle reset-prompt
    }
    _vbe_vcs_chpwd() {
        vcs_info_msg_0_=
    }
    _vbe_vcs_precmd() {
        async_flush_jobs vcs_info
        async_job vcs_info _vbe_vcs_info $PWD
    }

    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    () {
        local formats="${PRCH[branch]} %b%c%u"
        local actionformats="${formats}%F{default} ${PRCH[sep]} %F{green}%a%f"
        zstyle    ':vcs_info:*:*' formats           $formats
        zstyle    ':vcs_info:*:*' actionformats     $actionformats
        zstyle    ':vcs_info:*:*' stagedstr         "%F{green}${PRCH[circle]}%f"
        zstyle    ':vcs_info:*:*' unstagedstr       "%F{yellow}${PRCH[circle]}%f"
	zstyle    ':vcs_info:*:*' check-for-changes true

        zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

        +vi-git-untracked () {
            if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
                git status --porcelain 2> /dev/null | grep -q '??' ; then
                hook_com[staged]+="%F{black}${PRCH[circle]}%f"
            fi
        }

    }

    # Asynchronous VCS status
    source $ZSH/third-party/async.zsh
    async_init
    _vbe_vcs_async_start
    add-zsh-hook precmd _vbe_vcs_precmd
    add-zsh-hook chpwd _vbe_vcs_chpwd

    # Add VCS information to the prompt
    _vbe_add_prompt_vcs () {
	_vbe_prompt_segment cyan default ${vcs_info_msg_0_}
    }
}
