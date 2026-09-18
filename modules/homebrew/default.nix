{
  darwin =
    {
      host,
      lib,
      pkgs,
      config,
      ...
    }:
    let
      hostConfig = host.config;

      customCasks = config.dotfiles.homebrew.customCasks;
      customCasksTap = pkgs.callPackage ../../packages/homebrew-tap/package.nix {
        casks = customCasks;
      };
    in
    {
      options.dotfiles.homebrew.customCasks = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        description = "Custom casks (name -> path to a Cask ruby file) to install via a synthesized local tap.";
      };

      config = lib.mkIf hostConfig.homebrew.enable {
        nix-homebrew = {
          enable = true;
          user = hostConfig.user;
          autoMigrate = true;

          package = lib.mkIf (hostConfig.homebrew.repoUrl != null) (
            let
              src = fetchTree hostConfig.homebrew.repoUrl;
            in
            src
            // {
              name = "brew-${src.shortRev}";
              version = src.shortRev;
            }
          );

          taps = lib.mkIf (customCasks != { }) {
            "${customCasksTap.tapName}" = customCasksTap;
          };
        };

        homebrew = {
          enable = true;
          onActivation = {
            autoUpdate = false;
            upgrade = true;
            cleanup = "zap";
          };
          casks = customCasksTap.caskNames;
        };
      };
    };
}
