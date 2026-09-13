{ nixpkgs, nix-darwin }:
let
  ageIdentityPath = "/etc/age/dotfiles.key";
  ageRecipient = "age1qlrgcllugyaa9dadhjtyylldq0hpjsdxw7qu38v42j3s6ywzmuyqddqxrv";

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
          specialArgs = { inherit host inputs; };
          system = host.config.system;
          modules = [
            { system.stateVersion = "26.05"; }
            insecurePackagesModule
            inputs.agenix.nixosModules.default
            agenixIdentityModule
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

        ageEdit = pkgs.writeShellScriptBin "age-edit" ''
          set -euo pipefail

          if [ "$#" -ne 1 ]; then
            echo "usage: age-edit <file>" >&2
            exit 1
          fi
          file="$1"

          tmp=$(mktemp)
          trap 'shred -u "$tmp" 2>/dev/null || rm -f "$tmp"' EXIT
          chmod 600 "$tmp"

          if [ -f "$file" ]; then
            ${pkgs.age}/bin/age -d -i "${ageIdentityPath}" -o "$tmp" "$file"
          fi

          ${pkgs.vim}/bin/vim "$tmp"

          ${pkgs.age}/bin/age -e -r "${ageRecipient}" -o "$file.new" "$tmp"
          mv "$file.new" "$file"
        '';
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
