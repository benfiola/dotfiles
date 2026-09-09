{
  home =
    { host, lib, ... }:
    let
      config = host.config;
      allowedSigners = "~/.config/git/allowed_signers";

      includeFor = alias: identity: {
        condition = "hasconfig:remote.*.url:git@${alias}:*/**";
        contents = {
          user = {
            inherit (identity) name email;
            signingkey = "${identity.signingKey}";
          };
          commit.gpgsign = true;
          gpg.format = "ssh";
        };
      };

      signerLine =
        _: identity:
        "${identity.email} ${lib.removeSuffix "\n" (builtins.readFile (identity.signingKey + ".pub"))}";
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
}
