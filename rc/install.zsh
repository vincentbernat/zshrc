# -*- sh -*-

autoload colors ; colors

# Install or update ZSH on a remote host.
install-zsh() {
    local remote=$1
    local version=$(cd $ZSH ; git rev-parse HEAD)
    __() {
        # Check version
        ZSH="${ZSH:-$HOME/.zsh}"
        [ -d "$ZSH/run" ] || mkdir -p "$ZSH/run"
        if [ -f "$ZSH/run/version" ] && [ "$version" = "$(cat "$ZSH/run/version")" ]; then
            # Already up-to-date
            exit 0
        fi
        echo "$version" > "$ZSH/run/version"

        # Move history
        { mv "$ZSH"/history-* "$ZSH"/run || true } 2> /dev/null

        # Setup zshrc
        [[ ! -f $HOME/.zshrc ]] || mv $HOME/.zshrc $HOME/.zshrc.old
        ln -s "$ZSH"/zshrc $HOME/.zshrc

    }

    {
        echo 'set -e'
        echo "version=$version"

        # Hard work is done in __
        which __ | awk '{print a} (NR > 1) {a=$0}'

        # Uncompress the archive
        echo 'cat <<EOA | base64 -d | gzip -dc | tar -C $ZSH -xf -'
	(cd $ZSH ; git archive HEAD) | gzip -c | base64
        echo 'EOA'
    } > $ZSH/run/zsh-install.sh
    [[ -z $remote ]] || ssh $remote sh -s < $ZSH/run/zsh-install.sh
}
