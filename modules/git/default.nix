{
  home =
    { host, lib, ... }:
    let
      config = host.config;
      allowedSigners = "~/.config/git/allowed_signers";
      gitDir = if config.platform == "darwin" then "/Users/${config.user}/.git" else "/home/${config.user}/.git";

      keyPath =
        key:
        if lib.hasSuffix ".age" (builtins.baseNameOf key) then
          "${gitDir}/${lib.removeSuffix ".age" (builtins.baseNameOf key)}"
        else
          "${key}";

      pubKeyPath = key: lib.removeSuffix ".age" (toString key) + ".pub";

      includeFor = alias: identity: {
        condition = "hasconfig:remote.*.url:git@${alias}:*/**";
        contents = {
          user = {
            inherit (identity) name email;
            signingkey = keyPath identity.signingKey;
          };
          commit.gpgsign = true;
          gpg.format = "ssh";
        };
      };

      signerLine =
        _: identity:
        "${identity.email} ${lib.removeSuffix "\n" (builtins.readFile (pubKeyPath identity.signingKey))}";
    in
    lib.mkIf config.git.enable {
      programs.git = {
        enable = true;
        settings = {
          init.defaultBranch = "main";
          push.autoSetupRemote = true;
          user.useConfigOnly = true;
          gpg.ssh.allowedSignersFile = allowedSigners;
        };
        includes = lib.mapAttrsToList includeFor config.git.identities;
      };

      home.file.".config/git/allowed_signers" = lib.mkIf (config.git.identities != { }) {
        text = lib.concatStringsSep "\n" (lib.mapAttrsToList signerLine config.git.identities) + "\n";
      };
    };

  nixos =
    { host, lib, ... }:
    let
      config = host.config;
      nameOf = path: lib.removeSuffix ".age" (builtins.baseNameOf path);
      ageKeys = lib.filter (path: lib.hasSuffix ".age" (builtins.baseNameOf path)) (
        map (identity: identity.signingKey) (lib.attrValues config.git.identities)
      );
    in
    lib.mkIf (ageKeys != [ ]) {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "git-${nameOf path}";
          value = {
            file = path;
            path = "/home/${config.user}/.git/${nameOf path}";
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
        map (identity: identity.signingKey) (lib.attrValues config.git.identities)
      );
    in
    lib.mkIf (ageKeys != [ ]) {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "git-${nameOf path}";
          value = {
            file = path;
            path = "/Users/${config.user}/.git/${nameOf path}";
            owner = config.user;
          };
        }) ageKeys
      );
    };
}
