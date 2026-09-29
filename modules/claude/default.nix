let
  allowUnfree =
    args@{ host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf (config.claude.enable && config.claude.cask == null) {
      nixpkgs.config.allowUnfreePackages = [ "claude-code" ];
    };
in
{
  nixos = allowUnfree;

  darwin =
    args@{ host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkMerge [
      (allowUnfree args)
      (lib.mkIf (config.claude.enable && config.claude.cask != null) {
        homebrew.casks = [ config.claude.cask ];
      })
    ];

  home =
    {
      host,
      lib,
      pkgs,
      dotfilesLib,
      ...
    }:
    let
      config = host.config;
    in
    lib.mkIf config.claude.enable {
      home.packages = [
        (pkgs.callPackage ../../packages/claude-cleanup/package.nix { })
      ]
      ++ lib.optional (config.claude.cask == null) pkgs.claude-code
      ++ dotfilesLib.resolvePackages pkgs config.claude.extraPackages;
      home.file.".claude/CLAUDE.md".source = config.claude.claudeMd;
    };
}
