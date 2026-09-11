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

    fonts = {
      enable = true;
      packages = [
        "nerd-fonts.jetbrains-mono"
        "noto-fonts-color-emoji"
        "noto-fonts-cjk-sans"
      ];
    };

    locale = {
      enable = true;
      timeZone = "America/Los_Angeles";
      defaultLocale = "en_US.UTF-8";
    };

    starship.enable = true;
    zsh.enable = true;
    vim.enable = true;
    ls.enable = true;
    yubikey.enable = true;
    claude.enable = true;
    ghostty.enable = true;
    docker.enable = true;

    homebrew = {
      enable = true;
      repoUrl = null;
    };

    # unfree package names permitted for this config (nixpkgs allowUnfreePredicate)
    unfree = [ "claude-code" ];

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
