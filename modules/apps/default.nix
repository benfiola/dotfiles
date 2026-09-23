let
  apps = {
    alfred = {
      darwin.casks = [ "homebrew/cask/alfred" ];
    };
    bitwarden = {
      darwin.masApps = [
        {
          name = "Bitwarden";
          id = 1352778147;
        }
      ];
      nixos.packages = [ "bitwarden-desktop" ];
    };
    discord = {
      darwin.casks = [ "homebrew/cask/vesktop" ];
      nixos = {
        packages = [ "vesktop" ];
        insecurePackages = [ "electron-39.8.10" ];
      };
    };
    gimp = {
      darwin.casks = [ "homebrew/cask/gimp" ];
      nixos.packages = [ "gimp" ];
    };
    tidal = {
      darwin.casks = [ "homebrew/cask/tidal" ];
      nixos = {
        packages = [ "tidal-hifi" ];
        unfreePackages = [ "castlabs-electron" ];
      };
    };
    whatsapp = {
      darwin.casks = [ "homebrew/cask/whatsapp" ];
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
