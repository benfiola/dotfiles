{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.homebrew.enable {
      nix-homebrew = {
        enable = true;
        user = config.user;
        autoMigrate = true;

        package = lib.mkIf (config.homebrew.repoUrl != null) (
          let
            src = fetchTree config.homebrew.repoUrl;
          in
          src
          // {
            name = "brew-${src.shortRev}";
            version = src.shortRev;
          }
        );
      };

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = false;
          upgrade = true;
          cleanup = "zap";
        };
      };
    };
}
