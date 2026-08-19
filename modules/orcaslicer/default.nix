{
  darwin =
    { host, lib, ... }:
    let
      hostConfig = host.config;
    in
    lib.mkIf hostConfig.orcaslicer.enable {
      homebrew.casks = [ "orcaslicer" ];
    };

  home =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      hostConfig = host.config;
    in
    lib.mkIf (hostConfig.platform == "nixos" && hostConfig.orcaslicer.enable) {
      home.packages = [ (pkgs.callPackage ../../packages/orcaslicer/package.nix { }) ];
    };
}
