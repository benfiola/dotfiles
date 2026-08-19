{
  home =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.vim.enable {
      programs.vim = {
        enable = true;
        defaultEditor = true;
        extraConfig = "syntax on";
      };
    };
}
