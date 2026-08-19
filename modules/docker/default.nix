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

      home.file.".colima/_templates/default.yaml" = {
        text = lib.generators.toYAML { } (
          {
            arch = "aarch64";
            cpu = 2;
            disk = 100;
            memory = 2;
            mounts = [ ];
            nestedVirtualization = true;
            rosetta = true;
            runtime = "docker";
            vmType = "vz";
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
