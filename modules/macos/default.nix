{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.macos.enable {
      networking = {
        computerName = config.macos.computerName;
        hostName = config.macos.computerName;
        localHostName = config.macos.computerName;
      };

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
          "com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
            # spotlight: ctrl + opt + cmd + space
            "64" = {
              enabled = true;
              value = {
                type = "standard";
                parameters = [
                  32
                  49
                  1835008
                ];
              };
            };
          };
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
}
