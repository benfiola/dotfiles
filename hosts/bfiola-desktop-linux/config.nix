mkConfig:
mkConfig {
  system = "x86_64-linux";
  platform = "nixos";
  profile = "graphical";
  wireguard.tunnels = [
    ./wireguard-infrastructure.conf.age
    ./wireguard-management.conf.age
  ];
}
