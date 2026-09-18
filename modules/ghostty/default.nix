{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.ghostty.enable {
      homebrew.casks = [ "homebrew/cask/ghostty" ];
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
