{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = (import <nixpkgs> { }).lib;
    in
    {
      nixosConfiguration = lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ ];
      };
    };
}
