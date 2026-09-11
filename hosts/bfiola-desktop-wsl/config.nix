mkConfig:
mkConfig {
  system = "x86_64-linux";
  platform = "nixos";
  wsl = true;
  # virtualisation.docker doesn't work under WSL2 (see modules/docker).
  docker.enable = false;
}
