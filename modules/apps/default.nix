let
  apps = {
    alfred = {
      cask = "alfred";
    };
    bitwarden = {
      package = "bitwarden-desktop";
      mas = {
        name = "Bitwarden";
        id = 1352778147;
      };
    };
    contexts = {
      cask = "contexts";
    };
    discord = {
      package = "vesktop";
      cask = "vesktop";
      insecurePackages = [ "electron-39.8.10" ];
    };
    gimp = {
      package = "gimp";
      cask = "gimp";
    };
    magnet = {
      mas = {
        name = "Magnet";
        id = 441258766;
      };
    };
    proton = {
      package = "protonup-qt";
    };
    tidal = {
      package = "tidal-hifi";
      cask = "tidal";
      unfreePackages = [ "castlabs-electron" ];
    };
    whatsapp = {
      cask = "whatsapp";
    };
  };
in
{
  nixos =
    { host, lib, ... }:
    let
      config = host.config;
      enabled = lib.filterAttrs (name: _: config.${name}.enable) apps;
    in
    lib.mkIf (config.platform == "nixos") {
      dotfiles.insecurePackages = lib.pipe enabled [
        (lib.mapAttrsToList (_: app: app.insecurePackages or [ ]))
        lib.flatten
      ];
      nixpkgs.config.allowUnfreePackages = lib.pipe enabled [
        (lib.mapAttrsToList (_: app: app.unfreePackages or [ ]))
        lib.flatten
      ];
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
      enabled = lib.filterAttrs (name: _: config.${name}.enable) apps;
    in
    lib.mkIf (config.platform == "nixos") {
      assertions = lib.mapAttrsToList (name: app: {
        assertion = app ? package;
        message = "${name}.enable is set, but modules/apps has no NixOS package for ${name}";
      }) enabled;
      home.packages = lib.pipe enabled [
        (lib.filterAttrs (_: app: app ? package))
        (lib.mapAttrsToList (_: app: pkgs.${app.package}))
      ];
    };

  darwin =
    { host, lib, ... }:
    let
      config = host.config;
      enabled = lib.filterAttrs (name: _: config.${name}.enable) apps;
    in
    {
      assertions = lib.mapAttrsToList (name: app: {
        assertion = app ? cask || app ? mas;
        message = "${name}.enable is set, but modules/apps has no darwin cask/mas entry for ${name}";
      }) enabled;
      homebrew.casks = lib.pipe enabled [
        (lib.filterAttrs (_: app: app ? cask))
        (lib.mapAttrsToList (_: app: app.cask))
      ];
      homebrew.masApps = lib.pipe enabled [
        (lib.filterAttrs (_: app: app ? mas))
        (lib.mapAttrsToList (_: app: lib.nameValuePair app.mas.name app.mas.id))
        builtins.listToAttrs
      ];
    };
}
