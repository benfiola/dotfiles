{
  home =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;

      # `package` (path to a package.nix producing $out/extension.xpi) builds to a file:// install_url.
      builtExtensions = lib.mapAttrs (
        _id: ext:
        if ext ? package then
          let
            built = pkgs.callPackage ext.package { };
          in
          (removeAttrs ext [ "package" ]) // {
            install_url = "file://${built}/extension.xpi";
          }
        else
          ext
      ) config.firefox.extensions;
    in
    lib.mkIf config.firefox.enable {
      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;

        policies.ExtensionSettings = {
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            installation_mode = "force_installed";
          };
          "{26e789e7-acf2-4346-9381-ad473c245e43}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/nord-theme/latest.xpi";
            installation_mode = "force_installed";
          };
        } // builtExtensions;
      };
    };
}
