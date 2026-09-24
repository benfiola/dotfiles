{
  darwin =
    {
      host,
      lib,
      config,
      dotfilesLib,
      ...
    }:
    let
      hostConfig = host.config;
      home = config.users.users.${hostConfig.user}.home;
      tunnels = hostConfig.wireguard.tunnels;
      secretName = dotfilesLib.ageSecretName;
      fileName = path: lib.removePrefix "wireguard-" (secretName path);
    in
    lib.mkIf hostConfig.wireguard.enable {
      homebrew.masApps.WireGuard = 1451685025;

      age.secrets = lib.listToAttrs (
        map (path: {
          name = secretName path;
          value = {
            file = path;
            path = "${home}/.dotfiles/wireguard/${fileName path}";
            owner = hostConfig.user;
          };
        }) tunnels
      );
    };

  nixos =
    {
      host,
      lib,
      pkgs,
      dotfilesLib,
      ...
    }:
    let
      hostConfig = host.config;
      tunnels = hostConfig.wireguard.tunnels;
      secretName = dotfilesLib.ageSecretName;
      fileName = path: lib.removePrefix "wireguard-" (secretName path);
      interfaceName = path: lib.removeSuffix ".conf" (fileName path);
    in
    lib.mkIf hostConfig.wireguard.enable (
      lib.mkMerge [
        {
          age.secrets = lib.listToAttrs (
            map (path: {
              name = secretName path;
              value = {
                file = path;
                path = "/etc/wireguard/${fileName path}";
                mode = "0400";
              };
            }) tunnels
          );
        }

        (lib.mkIf (!hostConfig.wsl) {
          environment.systemPackages = [
            pkgs.wireguard-tools
          ];

          systemd.packages = [
            pkgs.wireguard-tools
          ];

          systemd.services."wg-quick@".path = [
            pkgs.coreutils
            pkgs.nftables
          ];

          system.activationScripts.wireguard-cleanup = ''
            declared="${lib.concatMapStringsSep " " interfaceName tunnels}"
            while read -r unit _; do
              name=''${unit#wg-quick@}
              name=''${name%.service}
              case " $declared " in
                *" $name "*) ;;
                *) ${pkgs.systemd}/bin/systemctl stop "$unit" ;;
              esac
            done < <(${pkgs.systemd}/bin/systemctl list-units --state=active --no-legend --plain 'wg-quick@*.service')
          '';

          security.polkit.extraConfig = ''
            polkit.addRule(function(action, subject) {
              if (
                action.id == "org.freedesktop.systemd1.manage-units" &&
                subject.user == "${hostConfig.user}" &&
                ["start", "stop", "restart"].indexOf(action.lookup("verb")) != -1 &&
                action.lookup("unit").match(/^wg-quick@.+\.service$/)
              ) {
                return polkit.Result.YES;
              }
            });
          '';
        })
      ]
    );

  home =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      hostConfig = host.config;
      tunnels = hostConfig.wireguard.tunnels;
      package = pkgs.callPackage ../../packages/wireguard-tray/package.nix { };
    in
    lib.mkIf (
      hostConfig.platform == "nixos" && !hostConfig.wsl && hostConfig.wireguard.enable && tunnels != [ ]
    ) {
      home.packages = [ package ];

      systemd.user.services.wireguard-tray = {
        Unit = {
          Description = "System tray toggle for wg-quick tunnels";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = lib.getExe package;
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
