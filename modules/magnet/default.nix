{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.magnet.enable {
      homebrew.masApps.Magnet = 441258766;

      system.defaults.CustomUserPreferences."com.crowdcafe.windowmagnet" = {
        hideMenuBarIcon = true;
        launchAtLogin = true;
      };
    };
}
