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
(( $+commands[tmux] )) && function tmux-pipe-pane() {
    umask 077
    local out=~/tmp/tmux-$HOST-$(date -I)-${1#%}.rawlog

    # Capture the current scrollback
    tmux capture-pane -epS - > $out
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' $out

    # Capture the live output
    >> $out

    # Reformat
    local current_limit=$(tmux show-options -gv history-limit)
    local new_limit=$(($(wc -l < $out) + 100))
    [[ $new_limit -gt $current_limit ]] && tmux set -g history-limit $new_limit
    {
        tmux new-window "cat $out ; tmux capture-pane -pS - | gzip -c > ${out%.rawlog}.log.gz"
    } always {
        tmux set -g history-limit ${history}
    }
}
