# TODO: generate valid hardware configuration
#
# bootloader (lanzaboote + systemd-boot + EFI, secure boot signed) defaults in lib.nix
# via mkBootloaderModule; override here (e.g. boot.lanzaboote.enable = false;
# boot.loader.systemd-boot.enable = true; boot.loader.grub.enable = true;) only if this
# host turns out to need legacy BIOS/GRUB, or can't do secure boot, instead.
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
