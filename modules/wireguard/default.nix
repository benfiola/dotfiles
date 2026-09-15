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
      nameOf = path: lib.removeSuffix ".age" (baseNameOf path);
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
              path = "/Users/${hostConfig.user}/.dotfiles/wireguard/${nameOf path}";
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
      nameOf = path: lib.removeSuffix ".age" (baseNameOf path);
    in
    lib.mkIf (hostConfig.wireguard.enable && tunnels != [ ]) {
      environment.systemPackages = [ pkgs.wireguard-tools ];

      age.secrets = lib.listToAttrs (
        map (path: {
          name = nameOf path;
          value = {
            file = path;
            path = "/etc/wireguard/${nameOf path}";
            mode = "0400";
          };
        }) tunnels
      )
      // lib.optionalAttrs hostConfig.wsl.enable (
        lib.listToAttrs (
          map (path: {
            name = "${nameOf path}-windows";
            value = {
              file = path;
              path = "/mnt/c/Users/${hostConfig.wsl.windowsUser}/.dotfiles/wireguard/${nameOf path}";
              mode = "0400";
              # the target is on the Windows side, so a symlink into WSL's
              # /run/agenix wouldn't resolve there - write the file directly
              symlink = false;
            };
          }) tunnels
        )
      );
    };
}
