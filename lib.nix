{ nixpkgs, nix-darwin }:
let
  fileEntries =
    dir:
    map (name: {
      inherit name;
      path = dir + "/${name}";
    }) (builtins.attrNames (builtins.readDir dir));

  mkHosts =
    { mkConfig, hostsDirs }:
    let
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
    in
    builtins.listToAttrs (
      map (entry: {
        inherit (entry) name;
        value = getHost entry.path;
      }) (builtins.concatMap fileEntries hostsDirs)
    );
in
{
  mkConfig = import ./config.nix { inherit (nixpkgs) lib; };

  mkSystems =
    {
      mkConfig,
      hostsDirs,
      modulesDirs,
      inputs,
    }:
    let
      hosts = mkHosts { inherit mkConfig hostsDirs; };

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

      insecurePackagesModule =
        { lib, config, ... }:
        {
          options.dotfiles.insecurePackages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Package name+version strings to allow despite being marked insecure.";
          };

          config.nixpkgs.config.permittedInsecurePackages = config.dotfiles.insecurePackages;
        };

      mkHomeManagerModule = host: {
        config = nixpkgs.lib.mkMerge [
          (nixpkgs.lib.mkIf (host.config.platform == "nixos") {
            users.users.${host.config.user}.isNormalUser = nixpkgs.lib.mkDefault true;
          })
          (nixpkgs.lib.mkIf (host.config.platform == "darwin") {
            users.users.${host.config.user}.home = "/Users/${host.config.user}";
          })
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit host inputs; };
            home-manager.sharedModules = [
              inputs.plasma-manager.homeModules.plasma-manager
            ];
            home-manager.users.${host.config.user} = {
              home.stateVersion = "26.05";
              imports = modulesByInput "home";
            };
          }
        ];
      };
    in
    {
      darwinConfigurations = nixpkgs.lib.mapAttrs (
        _: host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [
            {
              system.stateVersion = 7;
              system.primaryUser = host.config.user;
            }
            insecurePackagesModule
            inputs.home-manager.darwinModules.home-manager
            inputs.nix-homebrew.darwinModules.nix-homebrew
            (mkHomeManagerModule host)
          ]
          ++ (modulesByInput "darwin");
        }
      ) (hostsByPlatform "darwin");

      nixosConfigurations = nixpkgs.lib.mapAttrs (
        _: host:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [
            { system.stateVersion = "26.05"; }
            insecurePackagesModule
            inputs.agenix.nixosModules.default
            inputs.nixos-wsl.nixosModules.default
            { wsl.enable = host.config.wsl; }
            inputs.home-manager.nixosModules.home-manager
            (mkHomeManagerModule host)
            host.hardware
          ]
          ++ (modulesByInput "nixos");
        }
      ) (hostsByPlatform "nixos");
    };

  mkDevShells =
    {
      mkConfig,
      hostsDirs,
      inputs,
      packages ? (_: [ ]),
    }:
    let
      hosts = mkHosts { inherit mkConfig hostsDirs; };
      systems = nixpkgs.lib.unique (map (host: host.config.system) (builtins.attrValues hosts));
    in
    nixpkgs.lib.genAttrs systems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        default = pkgs.mkShell {
          packages = [ inputs.agenix.packages.${system}.default ] ++ packages system;
        };
      }
    );
}
