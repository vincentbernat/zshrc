# -*- sh -*-

# Incorporate git information into prompt

[[ $USERNAME != "root" ]] && {

    # Async helpers
    _vbe_vcs_info() {
        cd -q $1
        vcs_info
        print ${vcs_info_msg_0_}
    }
    _vbe_vcs_info_done() {
        vcs_info_msg_0_="$3"
        zle reset-prompt
    }

    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    () {
        local common="${PRCH[branch]} %b%c%u"
	zstyle ':vcs_info:*:*'   formats $common
	zstyle ':vcs_info:*:*'   actionformats ${common}"%{${fg[default]}%} ${PRCH[sep]} %{${fg[green]}%}"%a
	zstyle ':vcs_info:*:*'   stagedstr     "%{${fg[green]}%}${PRCH[circle]}"
	zstyle ':vcs_info:*:*'   unstagedstr   "%{${fg[yellow]}%}${PRCH[circle]}"
	zstyle ':vcs_info:*:*'   check-for-changes true
        zstyle ':vcs_info:hg*:*' get-revision true

        zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

        +vi-git-untracked(){
            if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
                git status --porcelain 2> /dev/null | grep -q '??' ; then
                hook_com[staged]+="%{${fg[black]}%}${PRCH[circle]}"
            fi
        }

    }

    # Asynchronous VCS status
    if is-at-least 5.2; then
        source $ZSH/third-party/async.zsh
        async_init
        async_start_worker vcs_info
        async_register_callback vcs_info _vbe_vcs_info_done
        add-zsh-hook precmd (){
            # Heuristic to check for a fuse-like filesystem
            if [[ $(zstat +blocks $PWD) -ne 0 ]]; then
                async_job vcs_info _vbe_vcs_info $PWD
            else
                vcs_info_msg_0_=
            fi
        }
        add-zsh-hook chpwd (){
            [[ -z vcs_info_msg_0_ ]] ||
                vcs_info_msg_0_="$vcs_info_msg_0_${PRCH[ellipsis]}"
        }
    else
        add-zsh-hook precmd (){
            # Heuristic to check for a fuse-like filesystem
            if [[ $(zstat +blocks $PWD) -ne 0 ]]; then
                vcs_info
            fi
        }
    fi

    _vbe_add_prompt_vcs () {
	_vbe_prompt_segment cyan default ${vcs_info_msg_0_}
    }
}
