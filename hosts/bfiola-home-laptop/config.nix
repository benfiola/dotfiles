mkConfig:
let
  localKey = ./github.com-localkey.age;
in
mkConfig {
  system = "aarch64-darwin";
  platform = "darwin";

  docker.colima = {
    cpu = 4;
    memory = 16;
    disk = 200;
  };
  git.identities."github.com-localkey" = {
    name = "Ben Fiola";
    email = "me@benfiola.com";
    signingKey = localKey;
  };
  ssh.hosts."github.com-localkey" = {
    key = localKey;
    hostname = "github.com";
  };
  wireguard.tunnels = [
    ./wireguard-infrastructure.conf.age
    ./wireguard-management.conf.age
    ./wireguard-personal.conf.age
  ];
}
