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

      localExtensions = lib.pipe config.firefox.extensions [
        lib.attrValues
        (lib.filter (ext: ext ? package))
        (map (ext: pkgs.callPackage ext.package { }))
      ];

      hostedExtensions = {
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        "{26e789e7-acf2-4346-9381-ad473c245e43}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/nord-theme/latest.xpi";
          installation_mode = "force_installed";
        };
      }
      // lib.filterAttrs (_id: ext: !(ext ? package)) config.firefox.extensions;
    in
    lib.mkIf config.firefox.enable {
      programs.firefox = {
        enable = true;
        package = pkgs.librewolf;

        globalExtensions = localExtensions;

        policies.ExtensionSettings = hostedExtensions;
        policies.Certificates.ImportEnterpriseRoots = true;
        policies.Preferences."xpinstall.signatures.required" = {
          Value = false;
          Status = "locked";
        };
      };
    };
}
