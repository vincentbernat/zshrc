# -*- sh -*-

autoload colors ; colors

# Install or update ZSH on a remote host.
# Needs Git
install-zsh() {
    local remote
    local work
    if (( $# != 1 )); then
	print "$fg_bold[red]Usage: $0 remote-host${reset_color}"
	return 2
    fi
    remote=$1
    work=$(mktemp -d)
    {
	local OK="$fg_bold[green]OK.${reset_color}"
	print -n "$fg[green]Building archive...${reset_color} "
	(cd $ZSH ; git archive HEAD) | tar -C $work -xf -
	print $OK
	print -n "$fg[green]Building installer...${reset_color} "
	makeself --gzip $work $ZSH/run/zsh-install.sh \
	    "$USER ZSH config files" zsh ./rc/install.zsh MAGIC
	print $OK
	print "$fg[green]Remote install...${reset_color} "
	scp $ZSH/run/zsh-install.sh ${remote}:
	ssh $remote sh ./zsh-install.sh
	print $OK
    } always {
	rm -rf $work
    }
}

# We can be executed to install ourself to the final destination
if [[ $1 == "MAGIC" ]]; then
    (( $+commands[rsync] )) || {
	print "$fg_bold[red]rsync not found, install it${reset_color}"
	exit 2
    }
    local OK="$fg[green]OK.${reset_color}"

    # Migrate history
    print -n "$fg[green]History migration...${reset_color} "
    [[ ! -d ~/.zsh/run ]] && mkdir -p ~/.zsh/run
    mv ~/.zsh/history-* ~/.zsh/run 2> /dev/null
    print $OK
    print "$fg[green]Installation...${reset_color} "
    rsync -rlp --exclude=run/\* --exclude=local/\* --delete . ~/.zsh/.
    [[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.old
    ln -s .zsh/zshrc ~/.zshrc
    print $OK
fi
