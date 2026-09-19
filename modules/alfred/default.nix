{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.alfred.enable {
      homebrew.casks = [ "homebrew/cask/alfred" ];
    };

  home =
    {
      host,
      lib,
      config,
      ...
    }:
    let
      hostConfig = host.config;
      prefsDir = "${config.home.homeDirectory}/source/github.com/benfiola/dotfiles/modules/alfred/Alfred.alfredpreferences";
    in
    lib.mkIf hostConfig.alfred.enable {
      home.file."Library/Application Support/Alfred/Alfred.alfredpreferences".source =
        config.lib.file.mkOutOfStoreSymlink prefsDir;
    };
}
