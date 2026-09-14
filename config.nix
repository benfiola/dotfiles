{ lib }:
host:
let
  profile = host.profile or "";

  githubKey = ./modules/ssh/github.com;

  common = {
    alfred.enable = false;
    bitwarden.enable = false;
    claude.enable = true;
    contexts.enable = false;
    discord.enable = false;
    docker = {
      enable = true;
      colima = {
        cpu = 2;
        memory = 2;
        disk = 100;
      };
    };
    firefox.enable = false;
    fonts.enable = false;
    ghostty.enable = false;
    gimp.enable = false;
    git = {
      enable = true;
      identities."github.com" = {
        name = "Ben Fiola";
        email = "me@benfiola.com";
        signingKey = githubKey;
      };
    };
    homebrew = {
      enable = false;
      repoUrl = null;
    };
    kde.enable = false;
    locale.enable = true;
    ls.enable = true;
    macos = {
      enable = false;
      computerName = host.hostName;
    };
    magnet.enable = false;
    nvidia.enable = false;
    orcaslicer.enable = false;
    padctl.enable = false;
    ssh = {
      enable = true;
      hosts."github.com".key = githubKey;
    };
    starship.enable = true;
    steam.enable = false;
    tidal.enable = false;
    user = "bfiola";
    vim.enable = true;
    vscode.enable = false;
    whatsapp.enable = false;
    wireguard = {
      enable = false;
      tunnels = [ ];
    };
    wsl = false;
    yubikey.enable = true;
    zsh.enable = true;
  };

  graphicalNixos = {
    bitwarden.enable = true;
    discord.enable = true;
    firefox.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    gimp.enable = true;
    kde.enable = true;
    orcaslicer.enable = true;
    padctl.enable = true;
    steam.enable = true;
    tidal.enable = true;
    vscode.enable = true;
    wireguard.enable = true;
  };

  darwin = {
    alfred.enable = true;
    bitwarden.enable = true;
    contexts.enable = true;
    discord.enable = true;
    firefox.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    gimp.enable = true;
    homebrew.enable = true;
    macos.enable = true;
    magnet.enable = true;
    orcaslicer.enable = true;
    tidal.enable = true;
    vscode.enable = true;
    whatsapp.enable = true;
    wireguard.enable = true;
  };

  os =
    if host.platform == "nixos" then
      lib.optionalAttrs (profile == "graphical") graphicalNixos
    else
      darwin;
in
lib.foldl' lib.recursiveUpdate { } [
  common
  os
  host
]
