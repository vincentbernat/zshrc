# -*- sh -*-

autoload colors ; colors

# Install or update ZSH on a remote host.
install-zsh() {
    local remote=$1
    local version=$(cd $ZSH ; git rev-parse HEAD)
    __() {
        # Find a base64 implementation
        if which base64 > /dev/null 2> /dev/null; then
            BASE64="base64 -d"
        elif which python > /dev/null 2> /dev/null; then
            BASE64="python -m base64 -d"
        elif which openssl > /dev/null 2> /dev/null; then
            BASE64="openssl base64 -d"
        else
            echo "Cannot find a base64 decoder" >&2
            return 1
        fi

        # Check version
        ZSH="${ZSH:-$HOME/.zsh}"
        [ -d "$ZSH/run" ] || mkdir -p "$ZSH/run"
        if [ -f "$ZSH/run/version" ] && [ "$version" = "$(cat "$ZSH/run/version")" ]; then
            # Already up-to-date
            return 0
        fi
        echo "$version" > "$ZSH/run/version"

        # Move history
        { mv "$ZSH"/history-* "$ZSH"/run || true } 2> /dev/null

        # Setup zshrc
        [ ! -f $HOME/.zshrc ] || mv $HOME/.zshrc $HOME/.zshrc.old
        ln -s "$ZSH"/zshrc $HOME/.zshrc

    }

    {
        echo 'set -e'
        echo "version=$version"

        # Hard work is done in __
        which __ | awk '{print a} (NR > 1) {a=$0}'

        # Uncompress the archive
        echo 'cat <<EOA | $BASE64 | gzip -dc | tar -C $ZSH -xf -'
	(cd $ZSH ; git archive HEAD) | gzip -c | base64
        echo 'EOA'
    } > $ZSH/run/zsh-install.sh
    [[ -z $remote ]] || ssh $remote sh -s < $ZSH/run/zsh-install.sh
}

# The resulting file can also be sourced in bashrc. For example:
#
#   . zsh-install && exec zsh -d
#
# Or:
#
#   export ZSH=~/.zsh.me
#   export ZDOTDIR=~/.zsh.me
#   . zsh-install && exec zsh -d
#
