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
    lib.mkIf config.claude.enable {
      home.packages = [ pkgs.claude-code ];
      home.file.".claude/CLAUDE.md".source = ./CLAUDE.md;
    };
}
