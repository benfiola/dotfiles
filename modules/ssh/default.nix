{
  home =
    { host, lib, ... }:
    let
      config = host.config;
      sshDir = if config.platform == "darwin" then "/Users/${config.user}/.ssh" else "/home/${config.user}/.ssh";
      keyPath =
        key:
        if lib.hasSuffix ".age" (builtins.baseNameOf key) then
          "${sshDir}/${lib.removeSuffix ".age" (builtins.baseNameOf key)}"
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
      nameOf = path: lib.removeSuffix ".age" (builtins.baseNameOf path);
      ageKeys = lib.filter (path: lib.hasSuffix ".age" (builtins.baseNameOf path)) (
        map (sshHost: sshHost.key) (lib.attrValues config.ssh.hosts)
      );
    in
    lib.mkIf (ageKeys != [ ]) {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "ssh-${nameOf path}";
          value = {
            file = path;
            path = "/home/${config.user}/.ssh/${nameOf path}";
            owner = config.user;
          };
        }) ageKeys
      );
    };

  darwin =
    { host, lib, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (builtins.baseNameOf path);
      ageKeys = lib.filter (path: lib.hasSuffix ".age" (builtins.baseNameOf path)) (
        map (sshHost: sshHost.key) (lib.attrValues config.ssh.hosts)
      );
    in
    lib.mkIf (ageKeys != [ ]) {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "ssh-${nameOf path}";
          value = {
            file = path;
            path = "/Users/${config.user}/.ssh/${nameOf path}";
            owner = config.user;
          };
        }) ageKeys
      );
    };
}
