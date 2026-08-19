{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;

      hostNames = builtins.attrNames (builtins.readDir ./hosts);

      parseHost =
        host:
        let
          configPath = ./hosts/${host}/config.nix;
          hardwarePath = ./hosts/${host}/hardware.nix;
        in
        {
          config = import configPath;
          hardware = if builtins.pathExists hardwarePath then import hardwarePath else { };
        };

      hosts = lib.genAttrs hostNames parseHost;

      hostsByPlatform = platform: lib.filterAttrs (_: host: host.config.platform == platform) hosts;
    in
    {

      nixosConfigurations = lib.mapAttrs (
        hostName: host:
        lib.nixosSystem {
          system = host.config.system;
          modules = [ { system.stateVersion = "26.11"; } ];
        }
      ) (hostsByPlatform "nixos");
    };
}
