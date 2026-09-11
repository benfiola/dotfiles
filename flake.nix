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

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager?ref=trunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, nix-darwin, ... }@inputs:
    let
      lib = import ./lib.nix { inherit nixpkgs nix-darwin; };

      systems = lib.mkSystems {
        mkConfig = lib.mkConfig;
        hostsDirs = [ ./hosts ];
        modulesDirs = [ ./modules ];
        inherit inputs;
      };
    in
    systems // { inherit lib; };
}
