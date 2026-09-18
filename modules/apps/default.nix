let
  apps = {
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
    { host, lib, dotfilesLib, ... }:
    let
      hostConfig = host.config;
      resolved = dotfilesLib.mkApps hostConfig apps;
    in
    lib.mkIf (hostConfig.platform == "nixos") {
      dotfiles.insecurePackages = resolved.insecurePackages;
      nixpkgs.config.allowUnfreePackages = resolved.unfreePackages;
    };

  home =
    {
      host,
      lib,
      pkgs,
      dotfilesLib,
      ...
    }:
    let
      hostConfig = host.config;
      resolved = dotfilesLib.mkApps hostConfig apps;
    in
    lib.mkIf (hostConfig.platform == "nixos") {
      home.packages = map (name: pkgs.${name}) resolved.packages;
    };

  darwin =
    { host, lib, dotfilesLib, ... }:
    let
      hostConfig = host.config;
      resolved = dotfilesLib.mkApps hostConfig apps;
    in
    {
      homebrew.casks = resolved.casks;
      homebrew.masApps = builtins.listToAttrs (
        map (masApp: lib.nameValuePair masApp.name masApp.id) resolved.masApps
      );
    };
}
