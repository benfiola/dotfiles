mkConfig:
mkConfig {
  system = "aarch64-darwin";
  platform = "darwin";
  wireguard.tunnels = [
    ./wireguard-infrastructure.conf.age
    ./wireguard-management.conf.age
    ./wireguard-personal.conf.age
  ];
}
