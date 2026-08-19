{
  nixos =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.padctl.enable {
      boot.kernelModules = [
        "uhid"
        "uinput"
      ];

      users.users.${config.user}.extraGroups = [ "input" ];

      services.udev.extraRules = ''
        # padctl UHID IMU nodes: tag as accelerometer so SDL/Steam recognize them as sensors instead of joysticks.
        SUBSYSTEM=="input", ATTRS{uniq}=="padctl/*", ATTRS{name}=="*IMU*", ENV{ID_INPUT_ACCELEROMETER}="1", ENV{ID_INPUT_JOYSTICK}=""

        SUBSYSTEM=="misc", KERNEL=="uinput", TAG+="uaccess", GROUP="input", MODE="0660"
        SUBSYSTEM=="misc", KERNEL=="uhid",   TAG+="uaccess", GROUP="input", MODE="0660"

        # Flydigi Vader 5 Pro
        ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="37d7", ATTRS{idProduct}=="2401", TAG+="uaccess", GROUP="input", MODE="0660"
        ACTION=="add", SUBSYSTEM=="input", ATTRS{idVendor}=="37d7", ATTRS{idProduct}=="2401", GROUP="input", MODE="0660"
        # padctl claims the vendor-class interfaces via libusb, which needs write access to the raw USB device node too, not just hidraw.
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="37d7", ATTRS{idProduct}=="2401", TAG+="uaccess", GROUP="input", MODE="0660"

        # xpad binds the pad's XInput interface before padctl can claim it; unbind only while a padctl daemon is running, so disabling padctl restores plain kernel gamepad support.
        ACTION=="add|bind", SUBSYSTEM=="usb", ATTRS{idVendor}=="37d7", ATTRS{idProduct}=="2401", DRIVER=="xpad", RUN+="/bin/sh -c '(ls /run/user/*/padctl.sock || ls /run/padctl/padctl.sock) >/dev/null 2>&1 && echo %k > /sys/bus/usb/drivers/xpad/unbind'"
        ACTION=="remove", SUBSYSTEM=="usb", ATTRS{idVendor}=="37d7", ATTRS{idProduct}=="2401", RUN+="/bin/sh -c '(ls /run/user/*/padctl.sock || ls /run/padctl/padctl.sock) >/dev/null 2>&1 || /sbin/modprobe xpad'"
      '';
    };

  home =
    {
      host,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      config = host.config;
      system = pkgs.stdenv.hostPlatform.system;
      package = inputs.padctl.packages.${system}.default;
      devicesDir = "${inputs.padctl}/devices";
    in
    lib.mkIf (config.padctl.enable && config.platform == "nixos") {
      home.packages = [ package ];

      systemd.user.services.padctl = {
        Unit = {
          Description = "padctl gamepad compatibility daemon";
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${package}/bin/padctl --config-dir ${devicesDir}";
          Restart = "on-failure";
          RestartSec = 3;
          StateDirectory = "padctl";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
