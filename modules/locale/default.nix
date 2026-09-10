{
  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.locale.enable {
      i18n.defaultLocale = config.locale.defaultLocale;
      time.timeZone = config.locale.timeZone;
    };

  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.locale.enable {
      time.timeZone = config.locale.timeZone;
    };
}
