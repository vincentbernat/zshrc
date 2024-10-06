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

I am targetting compatibility with Zsh 5.0.2 (the one in CentOS 7,
5.0.7 is in Jessie). Notably, I cannot use `local array=(el1 el2)`, as
this is only allowed since Zsh 5.1.

Installation
------------

If you are one of those young people not concerned about arbitrary code
execution, you can do:

    curl -sL https://github.com/vincentbernat/zshrc/releases/download/latest/zsh-install.sh | sh

There is also a Home Manager module:

```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            users.users.joe.shell = pkgs.zsh;
            programs.zsh.enable = true;
            home-manager.users.joe = { ... }: {
              imports = [ zshrc.homeManagerModules.default ];
              home.stateVersion = "24.05";
            };
          }
        ];
      };
    };
  };
}
```

License
-------

All the code is licensed as
[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/legalcode).
