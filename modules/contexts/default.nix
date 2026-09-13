{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (builtins.baseNameOf path);
      license = ./license.contexts-license.age;
    in
    lib.mkIf config.contexts.enable {
      homebrew.casks = [ "contexts" ];

      age.secrets."contexts-${nameOf license}" = {
        file = license;
        path = "/Users/${config.user}/.contexts/${nameOf license}";
        owner = config.user;
      };

      system.defaults.CustomUserPreferences."com.contextsformac.Contexts" = {
        CTPreferenceSearchShortcutFunctionKeyEnabled = 0;
        CTPreferenceWorkspaceConstrainWindowFrames = 0;
        CTPreferenceWorkspaceGrouping = "CTWorkspaceGroupingOne";
      };
    };
}
