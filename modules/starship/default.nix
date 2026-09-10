{
  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.starship.enable {
      programs.starship = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile ./starship.toml);
      };
    };
}
