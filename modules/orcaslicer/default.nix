{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.orcaslicer.enable {
      homebrew.casks = [ "homebrew/cask/orcaslicer" ];
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
    lib.mkIf (config.platform == "nixos" && config.orcaslicer.enable) {
      home.packages = [ (pkgs.callPackage ../../packages/orcaslicer/package.nix { }) ];
    };
}
