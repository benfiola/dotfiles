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
        # patch nix-homebrew to use system git
        system.activationScripts.homebrew.text = lib.mkOrder 750 (
          lib.concatMapStrings (
            prefix:
            lib.optionalString prefix.enable ''
              bin_brew="${prefix.prefix}/bin/brew"
              if [ -L "$bin_brew" ]; then
                generated="$(readlink -f "$bin_brew")"
                patched="${prefix.library}/.dotfiles-brew-system-git"
                sed -E \
                  -e 's#PATH="[^:"]*git-minimal[^:"]*:#PATH="#' \
                  -e 's#:[^:"]*git-minimal[^:"]*(:|")#\1#' \
                  "$generated" > "$patched"
                chmod +x "$patched"
                ln -sf "$patched" "$bin_brew"
              fi
            ''
          ) (builtins.attrValues config.nix-homebrew.prefixes)
        );

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
