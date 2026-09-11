{
  home =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;
    in
    lib.mkIf (config.docker.enable && config.platform == "darwin") {
      home.packages = [
        pkgs.colima
        pkgs.docker
        pkgs.docker-buildx
        pkgs.docker-compose
      ];
    };

  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf (config.docker.enable && !config.wsl) {
      virtualisation.docker.enable = true;
      users.users.${config.user}.extraGroups = [ "docker" ];
    };
}
