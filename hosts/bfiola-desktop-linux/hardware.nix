# TODO: generate valid hardware configuration
#
# bootloader (systemd-boot + EFI) defaults in lib.nix via mkBootloaderModule;
# override here (e.g. boot.loader.systemd-boot.enable = false; boot.loader.grub.enable
# = true;) only if this host turns out to need legacy BIOS/GRUB instead.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
