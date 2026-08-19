let
  gitSecrets =
    { host, lib, dotfilesLib, ... }:
    let
      config = host.config;
      nameOf = dotfilesLib.ageSecretName;
      formatOf = identity: identity.format or "ssh";
      keys = map (identity: identity.signingKey) (
        lib.filter (identity: formatOf identity == "ssh") (lib.attrValues config.git.identities)
      );
    in
    {
      age.secrets = lib.listToAttrs (
        map (path: {
          name = "git-${nameOf path}";
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
    { host, lib, osConfig, dotfilesLib, ... }:
    let
      config = host.config;
      allowedSigners = "~/.config/git/allowed_signers";
      nameOf = dotfilesLib.ageSecretName;

      keyPath = key: osConfig.age.secrets."git-${nameOf key}".path;

      pubKeyPath = key: lib.removeSuffix ".age" (toString key) + ".pub";

      formatOf = identity: identity.format or "ssh";

      signingContents =
        identity:
        if formatOf identity == "x509" then
          { gpg.format = "x509"; }
          // lib.optionalAttrs (identity ? program) { gpg.x509.program = identity.program; }
        else
          {
            gpg.format = "ssh";
            user.signingkey = keyPath identity.signingKey;
          };

      includeFor = alias: identity: {
        condition = "hasconfig:remote.*.url:git@${alias}:*/**";
        contents = lib.recursiveUpdate {
          user = { inherit (identity) name email; };
          commit.gpgsign = true;
        } (signingContents identity);
      };

      sshIdentities = lib.filterAttrs (_: identity: formatOf identity == "ssh") config.git.identities;

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

      home.file.".config/git/allowed_signers" = lib.mkIf (sshIdentities != { }) {
        text = lib.concatStringsSep "\n" (lib.mapAttrsToList signerLine sshIdentities) + "\n";
      };
    };

  nixos = gitSecrets;
  darwin = gitSecrets;
}
