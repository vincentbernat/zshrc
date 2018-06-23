# -*- sh -*-

# Incorporate git and svn information into prompt

(( $+functions[add-zsh-hook] )) && [[ $USERNAME != "root" ]] && {

    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git svn
    () {
        local common="${PRCH[branch]} %b%c%u"
	zstyle ':vcs_info:*:*'   formats $common
	zstyle ':vcs_info:*:*'   actionformats ${common}"%{${fg[default]}%} ${PRCH[sep]} %{${fg[green]}%}"%a
	zstyle ':vcs_info:svn:*' branchformat '%b:%r'
	zstyle ':vcs_info:hg*:*' hgrevformat '%r'
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

    _vbe_vcs_precmd () {
	vcs_info
    }
    add-zsh-hook precmd _vbe_vcs_precmd
    _vbe_add_prompt_vcs () {
	_vbe_prompt_segment cyan default ${vcs_info_msg_0_}
    }
}
