My `.zshrc`
===========

My `.zshrc` may not suit your needs. Feel free to read and
understand. Steal anything. My opinion is that you can't have an
universal `.zshrc`. If you don't agree, take a look at
[oh-my-zsh][ohmyzsh].

[ohmyzsh]: https://github.com/robbyrussell/oh-my-zsh

You need to create your own `.zshrc`. First solution is to symlink
`~/.zsh/zshrc`. The other solution is to source `~/.zsh/zshrc` from
your own `~/.zshrc`. The later case allows you to set the plugin you
want to enable.

You can copy your installation to a remote host with `install-zsh`
function.

`~/.zsh/run` contains runtime files, like history. `~/.zsh/local`
contains local files that should not be copied to a remote host.

`ln -s /nonexistent ~/tmp` and `exec zsh` will create `~/tmp` as a
symlink to a temporary directory. If the directory is destroyed, it
will be recreated. Don't do that if the home is shared across several
hosts.
