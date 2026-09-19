{
  darwin =
    {
      host,
      lib,
      config,
      dotfilesLib,
      ...
    }:
    let
      hostConfig = host.config;
      home = config.users.users.${hostConfig.user}.home;
      nameOf = dotfilesLib.ageSecretName;
      license = ./license.contexts-license.age;
    in
    lib.mkIf hostConfig.contexts.enable {
      homebrew.casks = [ "homebrew/cask/contexts" ];

      age.secrets."contexts-${nameOf license}" = {
        file = license;
        path = "${home}/.dotfiles/contexts/${nameOf license}";
        owner = hostConfig.user;
      };

      system.defaults.CustomUserPreferences."com.contextsformac.Contexts" = {
        CTPreferenceSearchShortcutFunctionKeyEnabled = 0;
        CTPreferenceWorkspaceConstrainWindowFrames = 0;
        CTPreferenceWorkspaceGrouping = "CTWorkspaceGroupingOne";
      };
    };
}
