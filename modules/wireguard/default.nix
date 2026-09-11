{
  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.wireguard.enable {
      homebrew.masApps.WireGuard = 1451685025;
    };

  nixos =
    {
      host,
      lib,
      config,
      ...
    }:
    let
      hostConfig = host.config;
      tunnel = hostConfig.wireguard.tunnel or null;
    in
    lib.mkIf (hostConfig.wireguard.enable && !hostConfig.wsl && tunnel != null) (
      let
        secretName = "${tunnel.name}-env";
      in
      {
        age.identityPaths = [ "/etc/age/host.key" ];
        age.secrets.${secretName}.file = ../../secrets + "/${tunnel.name}.env.age";

        networking.networkmanager.ensureProfiles = {
          environmentFiles = [ config.age.secrets.${secretName}.path ];
          profiles.${tunnel.name} = {
            connection = {
              id = tunnel.name;
              type = "wireguard";
              interface-name = tunnel.name;
            };
            wireguard.private-key = "$WG_PRIVATE_KEY";
            "wireguard-peer.${tunnel.peerPublicKey}" = {
              endpoint = tunnel.endpoint;
              allowed-ips = tunnel.allowedIPs;
              persistent-keepalive = 25;
            };
            ipv4 = {
              method = "manual";
              address1 = tunnel.address;
            };
            ipv6.method = "disabled";
          };
        };
      }
    );
}
