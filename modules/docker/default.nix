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
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !(config.docker.enable && config.wsl);
            message = "docker.enable is not supported on WSL hosts (wsl = true in config.nix)";
          }
        ];
      }
      (lib.mkIf (config.docker.enable && !config.wsl) {
        virtualisation.docker.enable = true;
        users.users.${config.user}.extraGroups = [ "docker" ];
      })
    ];
}
