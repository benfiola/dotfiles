{
  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.steam.enable {
      programs.steam.enable = true;
      nixpkgs.config.allowUnfreePackages = [
        "steam"
        "steam-unwrapped"
      ];
    };

  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.steam.enable {
      homebrew.casks = [ "homebrew/cask/steam" ];
    };

  home =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;
    in
    lib.mkIf (config.steam.enable && config.platform == "nixos") {
      home.packages = [
        pkgs.wineWow64Packages.staging
        pkgs.winetricks
        pkgs.protonup-qt
      ];
    };
}
