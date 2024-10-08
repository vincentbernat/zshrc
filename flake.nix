{
  description = "Vincent Bernat's zshrc";
  outputs = { self }: {
    homeManagerModules.default = { lib, ... }: {
      home.file = {
        ".zshenv".source = "${self}/zshenv";
        ".zshrc".source = "${self}/zshrc";
      } // lib.mapAttrs'
        (n: v: lib.nameValuePair ".zsh/${builtins.baseNameOf n}" { source = "${self}/${n}"; })
        (lib.filterAttrs (n: v: v == "directory" && n != "run") (builtins.readDir self));
    };
  };
}
