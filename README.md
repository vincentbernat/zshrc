My `.zshrc`
===========

My `.zshrc` may not suit your needs. Feel free to read and
understand. Steal anything. My opinion is that you can't have an
universal `.zshrc`. If you don't agree, take a look at
[Prezto](https://github.com/sorin-ionescu/prezto).

You need to create your own `.zshrc`. First solution is to symlink
`~/.zsh/zshrc`. The other solution is to source `~/.zsh/zshrc` from
your own `~/.zshrc`. The later case allows you to set the plugin you
want to enable.

You can copy your installation to a remote host with `install-zsh`
function.

`~/.zsh/run` contains runtime files, like history. `~/.zsh/local`
contains local files that should not be copied to a remote host.

Installation
------------

So, if you are one of those young generation not concerned about
arbitrary code execution, you can do:

    curl -s https://vincentbernat-zshrc.s3.amazonaws.com/zsh-install.sh | sh

License
-------

All the code is licensed as
[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/legalcode).
