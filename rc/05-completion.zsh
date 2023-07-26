# -*- sh -*-

() {
    emulate -L zsh
    [[ -o interactive ]] || return
    setopt extendedglob
    autoload -Uz compinit complist
    local zcd=$1                # compdump
    local zcdc=$1.zwc           # compiled compdump
    local zcda=$1.last          # last compilation
    local zcdl=$1.lock          # lock file
    local attempts=30
    : >> $zcd
    while (( attempts-- > 0 )) && ! ln $zcd $zcdl 2> /dev/null; do sleep 0.1; done
    {
        if [[ ! -e $zcda || -n $zcda(#qN.mh+24) ]]; then
            print -nu2 "Building completion cache..."
            # No compdump or too old
            \rm -f $ZSHRUN/zcompdump*(N.mM+6)
            compinit -u -d $zcd
            : > $zcda
            print -nu2 '\r'
        else
            # Reuse existing one
            compinit -C -d $zcd
        fi
        [[ ! -f $zcdc || $zcd -nt $zcdc ]] && rm -f $zcdc && {
                # On 9p, this fails because O_CREAT|O_WRONLY, 0444 fails
                if [[ $(findmnt -no FSTYPE $(stat -c %m $zcd 2> /dev/null) 2> /dev/null) != "9p" ]]; then
                    zcompile $zcd &!
                fi
            }
    } always {
        \rm -f $zcdl
    }
} $ZSHRUN/zcompdump-${ZSH_VERSION}-${#:-"$fpath"}

setopt auto_menu
setopt auto_remove_slash
setopt complete_in_word
setopt always_to_end
setopt glob_complete
unsetopt list_beep

# To find the current context: "Ctrl-x h" instead of "Tab".
# To debug more: "Ctrl-x ?".

zstyle ':completion:*' completer _expand_alias _complete _match _approximate
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' group-name ''
zstyle ':completion:*' insert-unambiguous
zstyle ':completion:*' menu select
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:match:*' original only
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSHRUN/cache/
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX + $#SUFFIX) / 3 )) numeric )'
zstyle ':completion:history-words:*' remove-all-dups true

zstyle ':completion:*:*:-command-:*:*' ignored-patterns 'cowbuilder-*'
zstyle ':completion:*:processes' command "ps -eo pid,user,comm,cmd -w -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:docker(|-*):*' option-stacking yes
zstyle ':completion:*:*:git-fetch:argument-rest:' tag-order '!remote-repositories'
zstyle ':completion:*:*:git-pull:argument-1:' tag-order '!remote-repositories'
zstyle ':completion:*:(ssh|scp|sftp|rsync):*:users' users root "$USERNAME" vincent

# Host completion
_vbe_custom_hosts() {
    # Complete ~/.zsh/local/hosts.*
    local host
    for host in $ZSH/local/hosts.*(N-.); do
        case $host in
            *\~) ;;
            *)
                _wanted hosts expl "remote host name" compadd "$@" ${(M)$(<$host):#${PREFIX}*}
                ;;
        esac
    done
}
zstyle -e ':completion:*' hosts '_vbe_custom_hosts "$@"'

# Don't use known_hosts_file (too slow)
zstyle ":completion:*:hosts" known-hosts-files ''

# In menu, select items with +
zmodload -i zsh/complist
bindkey -M menuselect "+" accept-and-menu-complete

# Use fzf when available
if (( $+commands[fzf] )) && [[ -f $ZSH/third-party/fzf-tab/fzf-tab.plugin.zsh ]]; then
    source $ZSH/third-party/fzf-tab/fzf-tab.plugin.zsh
    zstyle ':fzf-tab:*' fzf-bindings '+:toggle'
    zstyle ':fzf-tab:*' switch-group alt-left alt-right
    zstyle ':completion:*:descriptions' format ${PRCH[completion]}' %d'

    # Preview
    # zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
else
    zstyle ':completion:*:descriptions' format ${PRCH[completion]}' %B%d%b'
fi
