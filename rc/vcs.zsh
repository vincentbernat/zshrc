# -*- sh -*-

# Incorporate git information into prompt

[[ $USERNAME != "root" ]] && [[ $ZSH_NAME != "zsh-static" ]] && {

    # Patch for CVE-2021-45444
    # Impacted versions go from v5.0.3 to v5.8 (v5.8.1 is the first patched version)
    autoload -Uz is-at-least
    if is-at-least 5.8.1 || ! is-at-least 5.0.3; then
        return
    fi

    # Quote necessary $hook_com[<field>] items just before they are used
    # in the line "VCS_INFO_hook 'post-backend'" of the VCS_INFO_formats
    # function, where <field> is:
    #
    #   base:       the full path of the repository's root directory.
    #   base-name:  the name of the repository's root directory.
    #   branch:     the name of the currently checked out branch.
    #   revision:   an identifier of the currently checked out revision.
    #   subdir:     the path of the current directory relative to the
    #               repository's root directory.
    #   misc:       a string that may contain anything the vcs_info backend wants.
    #
    # This patch %-quotes these fields previous to their use in vcs_info hooks and
    # the zformat call and, eventually, when they get expanded in the prompt.
    # It's important to quote these here, and not later after hooks have modified the
    # fields, because then we could be quoting % characters from valid prompt sequences,
    # like %F{color}, %B, etc.
    #
    #  32   │ hook_com[subdir]="$(VCS_INFO_reposub ${hook_com[base]})"
    #  33   │ hook_com[subdir_orig]="${hook_com[subdir]}"
    #  34   │
    #  35 + │ for tmp in base base-name branch misc revision subdir; do
    #  36 + │     hook_com[$tmp]="${hook_com[$tmp]//\%/%%}"
    #  37 + │ done
    #  38 + │
    #  39   │ VCS_INFO_hook 'post-backend'
    #
    # This is especially important so that no command substitution is performed
    # due to malicious input as a consequence of CVE-2021-45444, which affects
    # zsh versions from 5.0.3 to 5.8.
    #
    autoload -Uz +X regexp-replace VCS_INFO_formats

    # We use $tmp here because it's already a local variable in VCS_INFO_formats
    typeset PATCH='for tmp (base base-name branch misc revision subdir) hook_com[$tmp]="${hook_com[$tmp]//\%/%%}"'
    # Unique string to avoid reapplying the patch if this code gets called twice
    typeset PATCH_ID=vcs_info-patch-9b9840f2-91e5-4471-af84-9e9a0dc68c1b
    # Only patch the VCS_INFO_formats function if not already patched
    if [[ "$functions[VCS_INFO_formats]" != *$PATCH_ID* ]]; then
        regexp-replace 'functions[VCS_INFO_formats]' \
                       "VCS_INFO_hook 'post-backend'" \
                       ': ${PATCH_ID}; ${PATCH}; ${MATCH}'
    fi
    unset PATCH PATCH_ID

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
                git status --porcelain 2> /dev/null | command grep -q '??' ; then
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
