let
  # System-level: register zsh as a login shell. macOS already defaults to zsh,
  # but NixOS needs it in /etc/shells before the user's shell can be set to it.
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

        # General-purpose interactive-shell helpers that belong to no single
        # tool. Tool-specific integration lives in that tool's module.
        initContent = ''
          src() {
            mkdir -p "$HOME/source"
            cd "$HOME/source"
          }
        '';
      };
    };

  nixos =
    { host, lib, pkgs, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.zsh.enable {
      programs.zsh.enable = true;
      users.users.${config.user}.shell = pkgs.zsh;
    };

  darwin = system;
}
