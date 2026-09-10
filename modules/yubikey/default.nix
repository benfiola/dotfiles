{
  home =
    { host, lib, pkgs, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.yubikey.enable {
      home.packages = [ pkgs.yubikey-manager ];
    };

  nixos =
    { host, lib, pkgs, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.yubikey.enable {
      # pcscd for PIV/OATH over CCID; udev rules so a non-root user can talk to
      # the key (also what lets `sk-` SSH keys work without sudo).
      services.pcscd.enable = true;
      services.udev.packages = [ pkgs.yubikey-personalization ];
    };
}
