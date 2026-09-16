let
  sshSecrets =
    { host, lib, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (baseNameOf path);
      keys = map (sshHost: sshHost.key) (lib.attrValues config.ssh.hosts);
    in
    {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "ssh-${nameOf path}";
          value = {
            file = path;
            owner = config.user;
          };
        }) keys
      );
    };
in
{
  home =
    { host, lib, osConfig, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (baseNameOf path);
      keyPath = key: osConfig.age.secrets."ssh-${nameOf key}".path;
    in
    lib.mkIf config.ssh.enable {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = lib.mapAttrs (alias: sshHost: {
          HostName = sshHost.hostname or alias;
          IdentityFile = keyPath sshHost.key;
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
        }) config.ssh.hosts;
      };

      services.ssh-agent.enable = lib.mkIf (config.platform == "nixos") true;
    };

  nixos = sshSecrets;
  darwin = sshSecrets;
}
