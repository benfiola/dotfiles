let
  fonts =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;
      resolve = name: lib.getAttrFromPath (lib.splitString "." name) pkgs;
    in
    lib.mkIf config.fonts.enable {
      fonts.packages = map resolve config.fonts.packages;
    };
in
{
  nixos = fonts;
  darwin = fonts;
}
