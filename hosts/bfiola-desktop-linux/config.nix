mkConfig:
let
  localKey = ./github.com-localkey.age;
in
mkConfig {
  system = "x86_64-linux";
  platform = "nixos";
  profile = "graphical";

  git.identities."github.com-localkey" = {
    name = "Ben Fiola";
    email = "me@benfiola.com";
    signingKey = localKey;
  };
  nvidia.enable = true;
  ssh.hosts."github.com-localkey" = {
    key = localKey;
    hostname = "github.com";
  };
  wireguard.tunnels = [
    ./wireguard-infrastructure.conf.age
    ./wireguard-management.conf.age
  ];
}
