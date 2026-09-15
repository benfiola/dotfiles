mkConfig:
let
  localKey = ./github.com-localkey.age;
in
mkConfig {
  system = "x86_64-linux";
  platform = "nixos";
  wsl = {
    enable = true;
    windowsUser = "bfiola";
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
}
