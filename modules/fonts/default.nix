let
  packages = [
    "nerd-fonts.jetbrains-mono"
    "noto-fonts-color-emoji"
    "noto-fonts-cjk-sans"
  ];

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
      fonts.packages = map resolve packages;
    };
in
{
  nixos = fonts;
  darwin = fonts;
}
