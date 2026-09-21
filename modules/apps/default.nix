let
  apps = {
    alfred = {
      casks = [ "homebrew/cask/alfred" ];
    };
    bitwarden = {
      packages = [ "bitwarden-desktop" ];
      masApps = [
        {
          name = "Bitwarden";
          id = 1352778147;
        }
      ];
    };
    discord = {
      packages = [ "vesktop" ];
      casks = [ "homebrew/cask/vesktop" ];
      insecurePackages = [ "electron-39.8.10" ];
    };
    gimp = {
      packages = [ "gimp" ];
      casks = [ "homebrew/cask/gimp" ];
    };
    tidal = {
      packages = [ "tidal-hifi" ];
      casks = [ "homebrew/cask/tidal" ];
      unfreePackages = [ "castlabs-electron" ];
    };
    whatsapp = {
      casks = [ "homebrew/cask/whatsapp" ];
    };
  };
in
{
  nixos =
    args@{ host, dotfilesLib, ... }: (dotfilesLib.mkApps (args // { inherit apps; })).nixosConfig;

  home =
    args@{
      host,
      pkgs,
      dotfilesLib,
      ...
    }:
    (dotfilesLib.mkApps (args // { inherit apps; })).homeConfig;

  darwin =
    args@{ host, dotfilesLib, ... }: (dotfilesLib.mkApps (args // { inherit apps; })).darwinConfig;
}
