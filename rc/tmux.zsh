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
                window=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' "ssh $host")
            else
                tmux split-window -t $window "ssh $host"
                tmux select-layout -t $window tiled
            fi
        done
        tmux set-window-option -t $window synchronize-panes on
        tmux select-window -t $window
    }

    # Slow pasting. First argument is tmux pane (X:Y.0)
    function tmux-slow-paste() {
        target="$1"
        shift
        cat "$@" | pv -W -q -L 500 | while IFS='' read -r line; do
            tmux send-keys -t "$target" -l "${line}"$'\n';
        done
    }

}
