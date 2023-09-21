# -*- sh -*-

# tmux-related stuff

(( $+commands[tmux] )) && [[ -n $TMUX ]] && {
    # Execute a command in a new pane and synchronise all panes. This
    # is a replacement of cluster-ssh. Here is how to execute it:
    #
    # tmux-cssh web-{001..005}.adm.dailymotion.com
    #
    function tmux-cssh() {
        local host
        local window
        for host in "$@"; do
            if [[ -z $window ]]; then
                window=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' "$SHELL --interactive -c '${SSH_COMMAND:-ssh} $host'")
            else
                tmux split-window -t $window "$SHELL --interactive -c '${SSH_COMMAND:-ssh} $host'"
                tmux select-layout -t $window tiled
            fi
        done
        tmux set-window-option -t $window synchronize-panes on
        tmux select-window -t $window
    }
    function tmux-cpssh() {
        SSH_COMMAND=pssh tmux-cssh "$@"
    }

    # Slow pasting. First argument is tmux pane (X:Y.0)
    function tmux-slow-paste() {
        local target="$1"
        shift
        cat "$@" | pv -W -q -L 500 | while IFS='' read -r line; do
            tmux send-keys -t "$target" -l "${line}"$'\n';
        done
    }
}

# Helper for pipe-pane to record a session
(( $+commands[tmux] )) && function _vbe_tmux-record-pane() {
    umask 077
    local out=~/tmp/tmux-$HOST-$(date -I)-${1#%}.rawlog

    # Capture the current scrollback
    tmux capture-pane -t $1 -JepS - > $out
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' $out

    # Capture the live output
    >> $out

    # Reformat
    local current_limit=$(tmux show-options -gv history-limit)
    tmux set -g history-limit 2147483647
    {
        tmux new-window -d "cat $out ; tmux capture-pane -t \$TMUX_PANE -JpS - | gzip -c > ${out%.rawlog}.log.gz"
    } always {
        tmux set -g history-limit ${current_limit}
    }
}

# Helper for pass
(( $+commands[tmux] )) && function _vbe_tmux-pass() {
    cd ${PASSWORD_STORE_DIR:-~/.password-store} 2> /dev/null || return
    local entry=$(print -l **/*.gpg | sed 's,\.gpg$,,' | fzf)
    [[ -n $entry ]] || return
    local pass=$(pass show $entry | head -1)
    [[ -n $pass ]] || return
    tmux send-keys -t $1 -l $pass
    tmux send-keys -t $1 enter
}

# Start a command inside ttyd
(( $+commands[tmux] )) && (( $+commands[ttyd] )) && {
    # Check what this gives access to with `tmux list-keys -T root`.
    function tmux-ttyd() {
        local -a args
        args=($@)
        ttyd \
            --browser \
            -t fontSize=18 \
            -t fontFamily='Iosevka Term SS18' \
            -o -p0 \
            tmux new-session "
              source $ZSH/zshrc ;
              tmux set-option -s prefix None ;
              tmux set-option -w remain-on-exit on ;
              tmux set-hook window-linked 'set-option -w remain-on-exit on' ;
              ${args}"
    }
    (( $+functions[compdef] )) && \
        compdef '_arguments -s -S "1: :_command_names" "*:: :_normal"' tmux-ttyd

    # To record a remote pane:
    #  tmux pipe-pane -o -t%53 "zsh -c 'source $ZSH/zshrc ; _vbe_tmux-record-pane #D'"
    # To respawn a remote window:
    #  tmux respawn-window -t%53
    # To start another window:
    #  tmux new-window -t \$10 "source $ZSH/zshrc ; ..."
}
