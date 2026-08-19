{
  nixos =
    {
      host,
      lib,
      config,
      ...
    }:
    let
      hostConfig = host.config;
    in
    lib.mkIf hostConfig.nvidia.enable {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.graphics.enable = true;
      hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        powerManagement.enable = true;
      };
      nixpkgs.config.allowUnfreePackages = [
        "nvidia-x11"
        "nvidia-settings"
      ];
    };
}
