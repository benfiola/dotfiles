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
        text = lib.generators.toYAML { } (
          {
            arch = "aarch64";
            vmType = "vz";
            rosetta = true;
            runtime = "docker";
            mounts = [ ];
            nestedVirtualization = true;
          }
          // config.docker.colima
        );
      };
    };

  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.docker.enable (
      lib.mkMerge [
        { users.users.${config.user}.extraGroups = [ "docker" ]; }
        (
          if config.wsl then
            { wsl.docker-desktop.enable = true; }
          else
            { virtualisation.docker.enable = true; }
        )
      ]
    );
}
