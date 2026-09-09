{
  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.ssh.enable {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = lib.mapAttrs (alias: sshHost: {
          HostName = sshHost.hostname or alias;
          IdentityFile = "${sshHost.key}";
          IdentitiesOnly = true;
          AddKeysToAgent = "yes";
        }) config.ssh.hosts;
      };

      services.ssh-agent.enable = lib.mkIf (config.platform == "nixos") true;
    };
}
