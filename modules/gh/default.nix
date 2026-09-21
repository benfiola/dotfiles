{
  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.gh.enable {
      programs.gh.enable = true;
    };
}
