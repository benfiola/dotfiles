{
  home =
    { host, lib, pkgs, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.ls.enable {
      # GNU coreutils so `ls` / `dircolors` behave the same on Linux and macOS.
      home.packages = [ pkgs.coreutils ];

      home.file.".config/dircolors".source = ./dircolors;

      programs.zsh = {
        shellAliases.ls = "ls --color=auto";
        initContent = ''eval "$(dircolors -b "$HOME/.config/dircolors")"'';
      };
    };
}
