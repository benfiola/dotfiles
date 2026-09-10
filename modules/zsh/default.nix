let
  system =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.zsh.enable {
      programs.zsh.enable = true;
    };
in
{
  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.zsh.enable {
      programs.zsh = {
        enable = true;

        initContent = ''
          src() {
            mkdir -p "$HOME/source"
            cd "$HOME/source"
          }
        '';
      };
    };

  nixos =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;
    in
    lib.mkIf config.zsh.enable {
      programs.zsh.enable = true;
      users.users.${config.user}.shell = pkgs.zsh;
    };

  darwin = system;
}
