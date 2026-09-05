{ nixpkgs, nix-darwin }:
{
  mkConfig = import ./config.nix;

  mkSystems =
    {
      mkConfig,
      hostsDirs,
      modulesDirs,
      inputs,
    }:
    let
      fileEntries =
        dir:
        map (name: {
          inherit name;
          path = dir + "/${name}";
        }) (builtins.attrNames (builtins.readDir dir));

      getHost =
        hostPath:
        let
          configPath = hostPath + "/config.nix";
          hardwarePath = hostPath + "/hardware.nix";
        in
        {
          config = (import configPath) mkConfig;
          hardware = if builtins.pathExists hardwarePath then import hardwarePath else { };
        };

      hosts = builtins.listToAttrs (
        map (entry: {
          inherit (entry) name;
          value = getHost entry.path;
        }) (builtins.concatMap fileEntries hostsDirs)
      );

      hostsByPlatform =
        platform: nixpkgs.lib.filterAttrs (_: host: host.config.platform == platform) hosts;

      getModule =
        modulePath:
        let
          module = import modulePath;
          empty = _: { };
        in
        {
          home = module.home or empty;
          nixos = module.nixos or empty;
          darwin = module.darwin or empty;
        };

      modulePaths = map (entry: entry.path) (builtins.concatMap fileEntries modulesDirs);
      modules = map getModule modulePaths;
      modulesByInput = inputName: map (module: module.${inputName}) modules;
    in
    {
      darwinConfigurations = nixpkgs.lib.mapAttrs (
        _: host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [ { system.stateVersion = 7; } ] ++ (modulesByInput "darwin");
        }
      ) (hostsByPlatform "darwin");

      nixosConfigurations = nixpkgs.lib.mapAttrs (
        _: host:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [
            { system.stateVersion = "26.05"; }
            host.hardware
          ]
          ++ (modulesByInput "nixos");
        }
      ) (hostsByPlatform "nixos");
    };
}
