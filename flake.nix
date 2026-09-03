{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=26.05";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin?ref=nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nix-darwin, ... }@inputs:
    let
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

      hosts = nixpkgs.lib.genAttrs hostNames parseHost;

      hostsByPlatform =
        platform: nixpkgs.lib.filterAttrs (_: host: host.config.platform == platform) hosts;
    in
    {
      config = import ./config.nix;

      darwinConfigurations = nixpkgs.lib.mapAttrs (
        hostName: host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [ { system.stateVersion = 7; } ];
        }
      ) (hostsByPlatform "darwin");

      nixosConfigurations = nixpkgs.lib.mapAttrs (
        hostName: host:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [ { system.stateVersion = "26.05"; } ];
        }
      ) (hostsByPlatform "nixos");
    };
}
