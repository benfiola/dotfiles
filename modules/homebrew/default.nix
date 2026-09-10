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
