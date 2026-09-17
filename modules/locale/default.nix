let
  timeZone = "America/Los_Angeles";
  defaultLocale = "en_US.UTF-8";
in
{
  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.locale.enable {
      i18n.defaultLocale = defaultLocale;
      time.timeZone = timeZone;
      time.hardwareClockInLocalTime = true;
    };

  darwin =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.locale.enable {
      time.timeZone = timeZone;
    };
}
