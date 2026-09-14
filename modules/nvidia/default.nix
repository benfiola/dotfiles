{
  nixos =
    {
      host,
      lib,
      config,
      ...
    }:
    let
      cfg = host.config;
    in
    lib.mkIf cfg.nvidia.enable {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.graphics.enable = true;
      hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };
      nixpkgs.config.allowUnfreePackages = [
        "nvidia-x11"
        "nvidia-settings"
      ];
    };
}
