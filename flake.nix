{
  description = "dotfiles";

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/ef34387ddd751e1ab8857adf4676492d32eb24ec";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:benfiola/nix-homebrew?ref=use-system-git";

    padctl = {
      url = "github:BANANASJIM/padctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager?ref=trunk";
      inputs.home-manager.follows = "home-manager";
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

      devShells = lib.mkDevShells {
        mkConfig = lib.mkConfig;
        hostsDirs = [ ./hosts ];
      };
    in
    systems // { inherit lib devShells; };
}
