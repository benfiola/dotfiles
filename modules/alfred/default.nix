{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.alfred.enable {
      homebrew.casks = [ "alfred" ];
    };

  home =
    { host, lib, config, ... }:
    let
      hostConfig = host.config;
      prefsDir = "${config.home.homeDirectory}/source/github.com/benfiola/dotfiles/modules/alfred/Alfred.alfredpreferences";
    in
    lib.mkIf hostConfig.alfred.enable {
    };
}
