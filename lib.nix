{ nixpkgs, nix-darwin }:
let
  ageIdentityPath = "/etc/age/dotfiles.key";
  ageRecipient = "age1qlrgcllugyaa9dadhjtyylldq0hpjsdxw7qu38v42j3s6ywzmuyqddqxrv";

  dotfilesLib = {
    ageSecretName = path: nixpkgs.lib.removeSuffix ".age" (baseNameOf path);

    mkApps =
      {
        host,
        apps,
        pkgs ? null,
        extraAppSources ? [ ],
        ...
      }:
      let
        config = host.config;
        enabled = nixpkgs.lib.filterAttrs (name: _: config.${name}.enable) apps;

        appsFor = platform: nixpkgs.lib.mapAttrs (_: app: app.${platform} or { }) enabled;

        collect =
          platformApps: field:
          nixpkgs.lib.flatten (
            nixpkgs.lib.mapAttrsToList (_: app: app.${field} or [ ]) platformApps
          );

        appSources = [
          {
            platform = "darwin";
            field = "casks";
            apply = casks: { homebrew.casks = casks; };
          }
          {
            platform = "darwin";
            field = "brews";
            apply = brews: { homebrew.brews = brews; };
          }
          {
            platform = "darwin";
            field = "masApps";
            apply = masApps: {
              homebrew.masApps = builtins.listToAttrs (
                map (masApp: nixpkgs.lib.nameValuePair masApp.name masApp.id) masApps
              );
            };
          }
          {
            platform = "nixos";
            field = "insecurePackages";
            apply = packages: { dotfiles.insecurePackages = packages; };
          }
          {
            platform = "nixos";
            field = "unfreePackages";
            apply = packages: { nixpkgs.config.allowUnfreePackages = packages; };
          }
          {
            platform = "home";
            field = "packages";
            apply = packages: { home.packages = map (name: pkgs.${name}) packages; };
          }
        ] ++ extraAppSources;

        renderPlatform =
          platform:
          let
            platformApps = if platform == "home" then appsFor config.platform else appsFor platform;
            sources = builtins.filter (source: source.platform == platform) appSources;
          in
          nixpkgs.lib.foldl' nixpkgs.lib.recursiveUpdate { } (
            map (source: source.apply (collect platformApps source.field)) sources
          );
      in
      {
        nixosConfig = nixpkgs.lib.mkIf (config.platform == "nixos") (renderPlatform "nixos");
        homeConfig = renderPlatform "home";
        darwinConfig = renderPlatform "darwin";
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

      mkWslModule =
        host:
        let
          config = host.config;
        in
        {
          wsl.enable = config.wsl;
          wsl.defaultUser = config.user;
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

      mkHomeManagerModule =
        host:
        let
          config = host.config;
        in
        {
          config = nixpkgs.lib.mkMerge [
            (nixpkgs.lib.mkIf (config.platform == "nixos") {
              networking.hostName = nixpkgs.lib.mkDefault config.hostName;
              users.users.${config.user} = {
                isNormalUser = nixpkgs.lib.mkDefault true;
                extraGroups = [ "wheel" ];
              };
            })
            (nixpkgs.lib.mkIf (config.platform == "darwin") {
              users.users.${config.user}.home = "/Users/${config.user}";
            })
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit host inputs dotfilesLib; };
              home-manager.sharedModules = [
                inputs.plasma-manager.homeModules.plasma-manager
              ];
              home-manager.users.${config.user} = {
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
