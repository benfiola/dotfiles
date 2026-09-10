{
  # nixpkgs ghostty doesn't build cleanly on darwin: install the app via cask
  # there, and let home-manager own only the config file.
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.ghostty.enable {
      homebrew.casks = [ "ghostty" ];
    };

  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.ghostty.enable {
      programs.ghostty = {
        enable = true;
        package = lib.mkIf (config.platform == "darwin") null;
        settings = {
          font-family = [
            ""
            "JetBrainsMono Nerd Font"
            "Helvetica"
          ];
          quit-after-last-window-closed = true;
          theme = "Nord";
          keybind = [
            "performable:page_up=scroll_page_up"
            "performable:page_down=scroll_page_down"
          ];
        };
      };
    };
}
