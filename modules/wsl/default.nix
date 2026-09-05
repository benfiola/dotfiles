{
  nixos = { host, ... }: { wsl.enable = host.config.wsl; };
}
