{
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
    lib.mkIf config.bf.enable {
      home.packages = [ (pkgs.callPackage ../../packages/bf/package.nix { }) ];
    };
}
