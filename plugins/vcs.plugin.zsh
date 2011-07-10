# -*- sh -*-

# Incorporate git and svn information into prompt

autoload -Uz vcs_info

zstyle ':vcs_info:*' enable git svn
() {
    local r='${PR_NO_COLOUR}'
    local common=$r'[${PR_LIGHT_GREEN}%b%c%u'
    local circle='o'
    [[ -o multibyte ]] && circle='●'
    zstyle ':vcs_info:git:*' formats '${PR_BLUE}±'$common$r']'
    zstyle ':vcs_info:svn:*' formats '${PR_BLUE}s'$common$r']'
    zstyle ':vcs_info:git:*' actionformats '${PR_BLUE}±'$common$r'|${PR_LIGHT_MAGENTA}%a'$r']'
    zstyle ':vcs_info:svn:*' actionformats '${PR_BLUE}s'$common$r'|${PR_LIGHT_MAGENTA}%a'$r']'
    zstyle ':vcs_info:svn:*' branchformat '%b${PR_GREY}:${PR_YELLOW}%r'
    zstyle ':vcs_info:*' stagedstr     '${PR_GREEN}'$circle
    zstyle ':vcs_info:*' unstagedstr   '${PR_YELLOW}'$circle
}
zstyle ':vcs_info:*' check-for-changes true

autoload add-zsh-hook
_vbe_vcs_precmd () {
    vcs_info
}
add-zsh-hook precmd _vbe_vcs_precmd

_vbe_add_prompt_vcs () {
    print -n '${(e)vcs_info_msg_0_}'
}
