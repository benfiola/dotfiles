{
  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.kde.enable {
      services.displayManager.sddm = {
        enable = true;
        theme = "breeze";
      };
      services.desktopManager.plasma6.enable = true;

      services.pipewire = {
        enable = true;
        pulse.enable = true;
      };

      networking.networkmanager.enable = true;
    };

  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf (config.kde.enable && config.platform == "nixos") {
      programs.plasma = {
        enable = true;

        workspace = {
          lookAndFeel = "org.kde.breezedark.desktop";
          colorScheme = "BreezeDark";
          iconTheme = "breeze-dark";
          cursor.theme = "breeze_cursors";
          clickItemTo = "select";
        };

        fonts.fixedWidth = {
          family = "JetBrainsMono Nerd Font";
          pointSize = 12;
        };

        input.keyboard = {
          repeatDelay = 200;
          repeatRate = 40;
        };

        krunner = {
          position = "center";
          shortcuts.launch = [
            "Alt+Space"
            "Alt+F2"
          ];
        };

        session.sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";

        shortcuts.kwin = {
          "Window Quick Tile Left" = "Meta+Left";
          "Window Quick Tile Right" = "Meta+Right";
          "Window Quick Tile Top" = "Meta+Up";
          "Window Quick Tile Bottom" = "Meta+Down";
          "Window Maximize" = [
            "Meta+Alt+Return"
            "Meta+PgUp"
          ];
        };

        configFile = {
          kdeglobals.KDE.ScrollbarLeftClickNavigatesByPage = false;
          krunnerrc.Plugins = {
            PowerDevilEnabled = false;
            appstreamEnabled = false;
            baloosearchEnabled = false;
            bookmarksEnabled = false;
            desktopsessionsEnabled = false;
            helprunnerEnabled = false;
            krunner_killEnabled = false;
            kwinEnabled = false;
            "org.kde.activities2Enabled" = false;
            "org.kde.windowedwidgetsEnabled" = false;
            placesEnabled = false;
            "plasma-desktopEnabled" = false;
            recentdocumentsEnabled = false;
            shellEnabled = false;
            windowsEnabled = false;
          };
        };
      };
    };
}
