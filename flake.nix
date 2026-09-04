{
  description = "dotfiles";

  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs?ref=26.05";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin?ref=nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nix-darwin, ... }@inputs:
    let
      # hosts
      hostNames = builtins.attrNames (builtins.readDir ./hosts);

      getHost =
        hostName:
        let
          configPath = ./hosts/${hostName}/config.nix;
          hardwarePath = ./hosts/${hostName}/hardware.nix;
        in
        {
          config = import configPath;
          hardware = if builtins.pathExists hardwarePath then import hardwarePath else { };
        };

      hosts = nixpkgs.lib.genAttrs hostNames getHost;

      hostsByPlatform =
        platform: nixpkgs.lib.filterAttrs (_: host: host.config.platform == platform) hosts;

      # modules
      moduleNames = builtins.attrNames (builtins.readDir ./modules);

      getModule =
        moduleName:
        let
          module = import ./modules/${moduleName};
          empty = _: { };
        in
        {
          home = module.home or empty;
          nixos = module.nixos or empty;
          darwin = module.darwin or empty;
        };

      modules = builtins.map getModule moduleNames;

      modulesByInput = inputName: builtins.map (module: module.${inputName}) modules;
    in
    {
      config = import ./config.nix;

      darwinConfigurations = nixpkgs.lib.mapAttrs (
        hostName: host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [ { system.stateVersion = 7; } ] ++ (modulesByInput "darwin");
        }
      ) (hostsByPlatform "darwin");

      nixosConfigurations = nixpkgs.lib.mapAttrs (
        hostName: host:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [
            { system.stateVersion = "26.05"; }
            host.hardware
          ]
          ++ (modulesByInput "nixos");
        }
      ) (hostsByPlatform "nixos");
    };
}
