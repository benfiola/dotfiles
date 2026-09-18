{ nixpkgs, nix-darwin }:
let
  ageIdentityPath = "/etc/age/dotfiles.key";
  ageRecipient = "age1qlrgcllugyaa9dadhjtyylldq0hpjsdxw7qu38v42j3s6ywzmuyqddqxrv";

  dotfilesLib = {
    ageSecretName = path: nixpkgs.lib.removeSuffix ".age" (baseNameOf path);

    mkApps =
      config: apps:
      let
        enabled = nixpkgs.lib.filterAttrs (name: _: config.${name}.enable) apps;
        collect =
          field: nixpkgs.lib.flatten (nixpkgs.lib.mapAttrsToList (_: app: app.${field} or [ ]) enabled);
      in
      {
        packages = collect "packages";
        casks = collect "casks";
        masApps = collect "masApps";
        insecurePackages = collect "insecurePackages";
        unfreePackages = collect "unfreePackages";
      };
  };

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
        name: hostPath:
        let
          configPath = hostPath + "/config.nix";
          hardwarePath = hostPath + "/hardware.nix";
          mkConfigForHost = args: mkConfig (nixpkgs.lib.recursiveUpdate { hostName = name; } args);
        in
        {
          config = (import configPath) mkConfigForHost;
          hardware = if builtins.pathExists hardwarePath then import hardwarePath else { };
        };
    in
    builtins.listToAttrs (
      map (entry: {
        inherit (entry) name;
        value = getHost entry.name entry.path;
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

      agenixIdentityModule = {
        age.identityPaths = [ ageIdentityPath ];
      };

      experimentalFeaturesModule = {
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };

      nixosStateVersionModule = {
        system.stateVersion = "26.05";
      };

      mkDarwinSystemModule = host: {
        system.stateVersion = 7;
        system.primaryUser = host.config.user;
      };

      mkWslModule = host: {
        wsl.enable = host.config.wsl;
        wsl.defaultUser = host.config.user;
      };

      mkBootloaderModule =
        host:
        {
          pkgs,
          lib,
          config,
          ...
        }:
        nixpkgs.lib.mkIf (!host.config.wsl) (
          let
            refindIconSize = "384-144";

            refindTheme = pkgs.callPackage ./packages/refind-theme-regular/package.nix {
              iconSize = refindIconSize;
              dark = true;
            };

            refindInstall = pkgs.callPackage ./packages/refind/package.nix {
              esp = config.boot.loader.efi.efiSysMountPoint;
              manageNvram = config.boot.loader.efi.canTouchEfiVariables;
              extraConfig = ''
                timeout 5
                dont_scan_dirs +,EFI/Linux,EFI/systemd,EFI/nixos,EFI/boot
                include themes/refind-theme-regular/theme.conf
                menuentry Linux {
                    icon EFI/refind/themes/refind-theme-regular/icons/${refindIconSize}/os_nixos.png
                    loader EFI/systemd/systemd-bootx64.efi
                }
              '';
              additionalDirs = {
                "themes/refind-theme-regular" = "${refindTheme}";
              };
            };
          in
          {
            boot.loader.systemd-boot.enable = nixpkgs.lib.mkDefault false;
            boot.loader.systemd-boot.configurationLimit = nixpkgs.lib.mkDefault 10;
            boot.loader.efi.canTouchEfiVariables = nixpkgs.lib.mkDefault true;
            boot.lanzaboote.enable = nixpkgs.lib.mkDefault true;
            boot.lanzaboote.pkiBundle = nixpkgs.lib.mkDefault "/var/lib/sbctl";

            environment.systemPackages = [
              pkgs.refind
              pkgs.sbctl
              pkgs.efibootmgr
            ];

            system.activationScripts.refind-install = {
              deps = [ ];
              text = lib.getExe refindInstall;
            };

            system.activationScripts.sbctl-sign-all = {
              deps = [ "refind-install" ];
              text = ''
                ${pkgs.sbctl}/bin/sbctl sign-all
              '';
            };
          }
        );

      mkHomeManagerModule = host: {
        config = nixpkgs.lib.mkMerge [
          (nixpkgs.lib.mkIf (host.config.platform == "nixos") {
            networking.hostName = nixpkgs.lib.mkDefault host.config.hostName;
            users.users.${host.config.user} = {
              isNormalUser = nixpkgs.lib.mkDefault true;
              extraGroups = [ "wheel" ];
            };
          })
          (nixpkgs.lib.mkIf (host.config.platform == "darwin") {
            users.users.${host.config.user}.home = "/Users/${host.config.user}";
          })
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit host inputs dotfilesLib; };
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
          specialArgs = { inherit host inputs dotfilesLib; };
          system = host.config.system;
          modules = [
            (mkDarwinSystemModule host)
            insecurePackagesModule
            experimentalFeaturesModule
            inputs.agenix.darwinModules.default
            agenixIdentityModule
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
          specialArgs = { inherit host inputs dotfilesLib; };
          system = host.config.system;
          modules = [
            nixosStateVersionModule
            insecurePackagesModule
            experimentalFeaturesModule
            inputs.agenix.nixosModules.default
            agenixIdentityModule
            inputs.nixos-wsl.nixosModules.default
            (mkWslModule host)
            inputs.lanzaboote.nixosModules.lanzaboote
            (mkBootloaderModule host)
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

        ageEdit = pkgs.callPackage ./packages/age-edit/package.nix {
          identityPath = ageIdentityPath;
          recipient = ageRecipient;
        };
      in
      {
        default = pkgs.mkShell {
          packages = [
            pkgs.age
            pkgs.vim
            ageEdit
          ]
          ++ packages system;
        };
      }
    );
}
