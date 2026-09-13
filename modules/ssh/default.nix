{
  home =
    { host, lib, osConfig, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (baseNameOf path);
      keyPath =
        key:
        if lib.hasSuffix ".age" (baseNameOf key) then
          osConfig.age.secrets."ssh-${nameOf key}".path
        else
          "${key}";
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

  nixos =
    { host, lib, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (baseNameOf path);
      ageKeys = lib.filter (path: lib.hasSuffix ".age" (baseNameOf path)) (
        map (sshHost: sshHost.key) (lib.attrValues config.ssh.hosts)
      );
    in
    lib.mkIf (ageKeys != [ ]) {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "ssh-${nameOf path}";
          value = {
            file = path;
            owner = config.user;
          };
        }) ageKeys
      );
    };

  darwin =
    { host, lib, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (baseNameOf path);
      ageKeys = lib.filter (path: lib.hasSuffix ".age" (baseNameOf path)) (
        map (sshHost: sshHost.key) (lib.attrValues config.ssh.hosts)
      );
    in
    lib.mkIf (ageKeys != [ ]) {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "ssh-${nameOf path}";
          value = {
            file = path;
            owner = config.user;
          };
        }) ageKeys
      );
    };
}
