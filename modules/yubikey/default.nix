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
    lib.mkIf config.yubikey.enable {
      home.packages = [ pkgs.yubikey-manager ];
    };

  nixos =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;
    in
    lib.mkIf config.yubikey.enable {
      services.pcscd.enable = true;
      services.udev.packages = [ pkgs.yubikey-personalization ];
    };
}
