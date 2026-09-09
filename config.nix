{ lib }:
host:
let
  profile = host.profile or "";

  githubKey = ./modules/ssh/github.com;

  common = {
    git = {
      enable = true;
      identities."github.com" = {
        name = "Ben Fiola";
        email = "me@benfiola.com";
        signingKey = githubKey;
      };
    };

    ssh = {
      enable = true;
      hosts."github.com".key = githubKey;
    };

    user = "bfiola";
    wsl = false;
  };

  os =
    if host.platform == "nixos" then
      { } // (if profile == "graphical" then { } else { })
    else if host.platform == "darwin" then
      { }
    else
      { };
in
lib.foldl' lib.recursiveUpdate { } [
  common
  os
  host
]
