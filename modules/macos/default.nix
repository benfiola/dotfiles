{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.macos.enable {
      system.defaults = {
        dock = {
          autohide = true;
          autohide-delay = 15.0;
          autohide-time-modifier = 1.0;
          minimize-to-application = true;
          persistent-apps = [ ];
          show-process-indicators = true;
          show-recents = false;
          static-only = true;
        };

        finder = {
          AppleShowAllFiles = true;
          FXEnableExtensionChangeWarning = false;
          FXPreferredViewStyle = "Nlsv";
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowPathbar = true;
          ShowRemovableMediaOnDesktop = true;
          ShowStatusBar = true;
          _FXSortFoldersFirst = true;
        };

        NSGlobalDomain = {
          ApplePressAndHoldEnabled = false;
          AppleShowScrollBars = "Always";
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          "com.apple.keyboard.fnState" = true;
        };

        CustomUserPreferences = {
          NSGlobalDomain.WebKitDeveloperExtras = true;
          "com.apple.finder".WarnOnEmptyTrash = false;
          "com.apple.systempreferences".NSQuitAlwaysKeepsWindows = false;
          "com.apple.Safari" = {
            IncludeDevelopMenu = true;
            ShowFullURLInSmartSearchField = true;
            WebKitDeveloperExtrasEnabledPreferenceKey = true;
            "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
          };
        };
      };
    };

  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    {
      assertions = [
        {
          assertion = !(config.macos.enable && config.platform != "darwin");
          message = "macos.enable is not supported outside darwin";
        }
      ];
    };
}
