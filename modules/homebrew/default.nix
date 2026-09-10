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
        # adopt an existing /opt/homebrew or /usr/local install instead of erroring
        autoMigrate = true;
      };

      homebrew = {
        enable = true;
        onActivation = {
          # keep rebuilds fast; refresh explicitly with `brew update`
          autoUpdate = false;
          upgrade = true;
          # remove anything not declared by a module (fully declarative)
          cleanup = "zap";
        };
      };
    };
}
