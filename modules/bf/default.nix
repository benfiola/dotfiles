{
  home =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;
    in
    lib.mkIf config.bf.enable {
      home.packages = [ (pkgs.callPackage ../../packages/bf/package.nix { }) ];

      # `bf worktrees` prints the chosen path so the shell can cd to it
      programs.zsh.initContent = ''
        bf() {
          case "$1" in
            worktrees)
              local out
              out="$(command bf "$@")" || return
              [[ -d "$out" ]] && cd "$out"
              ;;
            *)
              command bf "$@"
              ;;
          esac
        }
      '';
    };
}
