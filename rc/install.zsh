# -*- sh -*-

# Install or update ZSH on a remote host.
install-zsh() {
    local version=$(cd $ZSH ; git rev-parse HEAD)
    local __() {
        # Check version
        ZDOTDIR="${ZDOTDIR:-$HOME}"
        ZSH="${ZSH:-$HOME/.zsh}"
        [ -d "$ZSH/run" ] || mkdir -p "$ZSH/run"
        if [ -f "$ZSH/run/version" ] && [ "$version" = "$(cat "$ZSH/run/version")" ]; then
            # Already up-to-date
            return 0
        fi

        # Find a base64 implementation
        if which base64 > /dev/null 2> /dev/null; then
            BASE64="base64 -d"
        elif which openssl > /dev/null 2> /dev/null; then
            BASE64="openssl base64 -d"
        elif which python3 > /dev/null 2> /dev/null; then
            BASE64="python3 -m base64 -d"
        elif which python > /dev/null 2> /dev/null; then
            BASE64="python -m base64 -d"
        else
            echo "Cannot find a base64 decoder" >&2
            return 1
        fi

        echo "$version" > "$ZSH/run/version"

        # Move history
        { mv "$ZSH"/history-* "$ZSH"/run || true } 2> /dev/null

        # Setup zshrc
        for rc in zshrc zshenv; do
            [ ! -f $ZDOTDIR/.${rc} ] || mv $ZDOTDIR/.${rc} $ZDOTDIR/.${rc}.old
            ln -s "$ZSH"/${rc} $ZDOTDIR/.${rc}
        done

        # Remove old files
        for f in $ZSH/*; do
            case ${f##*/} in
                local|run) ;;
                *)
                    rm -rf "$f"
            esac
        done

    }

    {
        echo 'upgrade() {'
        echo 'set -e'
        echo "version=$version"

        # Hard work is done in __
        which __ | awk '{print a} (NR > 1) {a=$0}'

        # Uncompress the archive
        echo 'cat <<EOA | $BASE64 | gzip -dc | tar -C $ZSH -xf -'
	(
            cd $ZSH ; git ls-files | grep -vFx .gitmodules | \
                while read f; do [[ -d $f ]] || echo $f ; done | \
                tar --owner=root --group=root --numeric-owner -zhcf - -T - | base64
        )
        echo 'EOA'
        echo '}'
        echo 'upgrade'
    } > $ZSH/run/zsh-install.sh

    # When invoked with -b, replace .bashrc
    # Can use an identity file with -i
    local -a bash identity
    zparseopts -D b=bash i:=identity
    (( $# == 0 )) || for h in $@; do
        {
            cat $ZSH/run/zsh-install.sh
            (( $+bash[1] )) && echo 'echo '"'"'[ -z "$PS1" ] || exec zsh -d'"'"' > ~/.bashrc'
        } | ssh ${identity[2]+-i} ${identity[2]} $h sh -s
    done
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
# Upload using:
#  s3cmd put -P $ZSH/run/zsh-install.sh s3://vincentbernat-zshrc
#
# Policy is the following:
#  {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "Stmt1424709181000",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:PutObject",
#                 "s3:PutObjectAcl",
#                 "s3:DeleteObject"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::vincentbernat-zshrc/zsh-install.sh"
#             ]
#         },
#         {
#             "Sid": "Stmt1424709181001",
#             "Effect": "Allow",
#             "Action": [
#                 "s3:GetBucketLocation"
#             ],
#             "Resource": [
#                 "arn:aws:s3:::vincentbernat-zshrc"
#             ]
#         }
#     ]
#  }
