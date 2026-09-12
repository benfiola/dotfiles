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

      home.file.".colima/_templates/default.yaml" = lib.mkIf (config.docker.colima != { }) {
        text = lib.generators.toYAML { } config.docker.colima;
      };
    };

  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf (config.docker.enable) {
      virtualisation.docker.enable = true;
      users.users.${config.user}.extraGroups = [ "docker" ];
    };
}
