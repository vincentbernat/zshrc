# -*- sh -*-

# Definition of profiles is quite personal, protect them
[[ $USER != "bernat" ]] || {
    zstyle ':chpwd:profiles:/home/*/code/debian(|/|/*)'    profile debian
    zstyle ':chpwd:profiles:/home/*/code/exoscale(|/|/*)'  profile exoscale

    chpwd_profile_debian() {
        [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
        export DEBEMAIL=bernat@debian.org
        export GIT_AUTHOR_EMAIL=$DEBEMAIL
        export GIT_COMMITTER_EMAIL=$DEBEMAIL
    }

    chpwd_profile_exoscale() {
        [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
        export DEBEMAIL=Vincent.Bernat@exoscale.ch
        export GIT_AUTHOR_EMAIL=$DEBEMAIL
        export GIT_COMMITTER_EMAIL=$DEBEMAIL
    }

    chpwd_profile_default() {
        [[ ${profile} == ${CHPWD_PROFILE} ]] && return 1
        export DEBEMAIL=bernat@debian.org
        unset GIT_AUTHOR_EMAIL
        unset GIT_COMMITTER_EMAIL
    }
}

# Stolen from: http://git.grml.org/?p=grml-etc-core.git;f=etc/zsh/zshrc;hb=HEAD#l1558
#
# chpwd_profiles(): Directory Profiles, Quickstart:
#
# In .zshrc.local:
#
#   zstyle ':chpwd:profiles:/usr/src/grml(|/|/*)'   profile grml
#   zstyle ':chpwd:profiles:/usr/src/debian(|/|/*)' profile debian
#   chpwd_profiles
#
# For details see the `grmlzshrc.5' manual page.
function chpwd_profiles() {
    local profile context
    local -i reexecute

    context=":chpwd:profiles:$PWD"
    zstyle -s "$context" profile profile || profile='default'
    zstyle -T "$context" re-execute && reexecute=1 || reexecute=0

    if (( ${+parameters[CHPWD_PROFILE]} == 0 )); then
        typeset -g CHPWD_PROFILE
        local CHPWD_PROFILES_INIT=1
        (( ${+functions[chpwd_profiles_init]} )) && chpwd_profiles_init
    elif [[ $profile != $CHPWD_PROFILE ]]; then
        (( ${+functions[chpwd_leave_profile_$CHPWD_PROFILE]} )) \
            && chpwd_leave_profile_${CHPWD_PROFILE}
    fi
    if (( reexecute )) || [[ $profile != $CHPWD_PROFILE ]]; then
        (( ${+functions[chpwd_profile_$profile]} )) && chpwd_profile_${profile}
    fi

    CHPWD_PROFILE="${profile}"
    return 0
}

chpwd_functions=(${chpwd_functions} chpwd_profiles)

# Init
chpwd_profiles
