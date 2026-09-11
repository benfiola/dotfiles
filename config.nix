{ lib }:
host:
let
  profile = host.profile or "";

  githubKey = ./modules/ssh/github.com;

  common = {
    claude.enable = true;
    docker.enable = true;
    fonts = {
      enable = false;
      packages = [
        "nerd-fonts.jetbrains-mono"
        "noto-fonts-color-emoji"
        "noto-fonts-cjk-sans"
      ];
    };
    ghostty.enable = false;
    git = {
      enable = true;
      identities."github.com" = {
        name = "Ben Fiola";
        email = "me@benfiola.com";
        signingKey = githubKey;
      };
    };
    homebrew = {
      enable = true;
      repoUrl = null;
    };
    locale = {
      enable = true;
      timeZone = "America/Los_Angeles";
      defaultLocale = "en_US.UTF-8";
    };
    ls.enable = true;
    ssh = {
      enable = true;
      hosts."github.com".key = githubKey;
    };
    starship.enable = true;
    user = "bfiola";
    vim.enable = true;
    wsl = false;
    yubikey.enable = true;
    zsh.enable = true;
  };

  graphical = {
    fonts.enable = true;
    ghostty.enable = true;
  };

  os =
    if host.platform == "nixos" then
      lib.optionalAttrs (profile == "graphical") graphical
    else
      # darwin is always graphical, so it doesn't consult `profile`.
      graphical;
in
lib.foldl' lib.recursiveUpdate { } [
  common
  os
  host
]
