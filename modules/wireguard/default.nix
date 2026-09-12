{
  darwin =
    {
      host,
      lib,
      ...
    }:
    let
      hostConfig = host.config;
      tunnels = hostConfig.wireguard.tunnels;
      nameOf = path: lib.removeSuffix ".conf.age" (builtins.baseNameOf path);
    in
    lib.mkMerge [
      (lib.mkIf hostConfig.wireguard.enable {
        homebrew.masApps.WireGuard = 1451685025;
      })
      (lib.mkIf (hostConfig.wireguard.enable && tunnels != [ ]) {
        age.secrets = lib.listToAttrs (
          map (path: {
            name = nameOf path;
            value = {
              file = path;
              path = "/Users/${hostConfig.user}/.wireguard/${nameOf path}.conf";
              owner = hostConfig.user;
            };
          }) tunnels
        );
      })
    ];

  nixos =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      hostConfig = host.config;
      tunnels = hostConfig.wireguard.tunnels;
      nameOf = path: lib.removeSuffix ".conf.age" (builtins.baseNameOf path);
    in
    lib.mkIf (hostConfig.wireguard.enable && tunnels != [ ]) {
      environment.systemPackages = [ pkgs.wireguard-tools ];

      age.secrets = lib.listToAttrs (
        map (path: {
          name = nameOf path;
          value = {
            file = path;
            path = "/etc/wireguard/${nameOf path}.conf";
            mode = "0400";
          };
        }) tunnels
      );
    };
}
