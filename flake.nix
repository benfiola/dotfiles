{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
    in
    {
      nixosConfiguration = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ ];
      };
    };
}
