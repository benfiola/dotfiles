let
  system =
    { host, lib, ... }:
    let
      config = host.config;
    in
    lib.mkIf config.vscode.enable {
      nixpkgs.config.allowUnfreePackages = [ "vscode" ];
    };
in
{
  nixos =
    {
      host,
      lib,
      pkgs,
      ...
    }:
    let
      config = host.config;
    in
    lib.mkMerge [
      (system { inherit host lib; })
      (lib.mkIf config.wsl.enable {
        programs.nix-ld.enable = true;
        environment.systemPackages = [ pkgs.wget ];
      })
    ];
  darwin = system;

  home =
    {
      host,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      config = host.config;
      pkgsExt = import inputs.nixpkgs {
        inherit (pkgs) system;
        config.allowUnfreePackages = [
          "vscode-extension-anthropic-claude-code"
          "vscode-extension-ms-vscode-remote-remote-containers"
        ];
        overlays = [ inputs.nix-vscode-extensions.overlays.default ];
      };
      marketplace = pkgsExt.vscode-marketplace;

      extensions = with marketplace; [
        anthropic.claude-code
        arcticicestudio.nord-visual-studio-code
        esbenp.prettier-vscode
        ms-azuretools.vscode-containers
        ms-vscode-remote.remote-containers
        pkief.material-icon-theme
        rohit-gohri.format-code-action
        usernamehw.errorlens
      ];

      userSettings = {
        "chat.disableAIFeatures" = true;
        "claudeCode.hideOnboarding" = true;
        "claudeCode.preferredLocation" = "sidebar";
        "claudeCode.selectedModel" = "haiku";
        "claudeCode.useCtrlEnterToSend" = true;
        "[dockerfile]"."editor.defaultFormatter" = "ms-azuretools.vscode-containers";
        "editor.codeActionsOnSave" = [
          "source.organizeImports"
          "source.unusedImports"
          "source.formatDocument"
        ];
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.fontFamily" = "'JetBrainsMono Nerd Font','Helvetica'";
        "editor.fontLigatures" = true;
        "editor.tabSize" = 2;
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 5000;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "prettier.tabWidth" = 2;
        "remote.autoForwardPortsSource" = "hybrid";
        "telemetry.feedback.enabled" = false;
        "terminal.integrated.initialHint" = false;
        "terminal.integrated.scrollback" = 10001;
        "terminal.integrated.stickyScroll.enabled" = false;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "update.showReleaseNotes" = false;
        "workbench.colorTheme" = "Nord";
        "workbench.editor.empty.hint" = "hidden";
        "workbench.editor.enablePreview" = false;
        "workbench.secondarySideBar.defaultVisibility" = "hidden";
        "workbench.startupEditor" = "none";
      };

      windowsDotfiles = "/mnt/c/Users/${config.wsl.windowsUser}/.dotfiles/vscode";
      windowsSettingsFile = pkgs.writeText "settings.json" (builtins.toJSON userSettings);
      windowsExtensionsFile = pkgs.writeText "extensions.txt" (
        lib.concatMapStrings (ext: "${ext.vscodeExtUniqueId}\n") extensions
      );
    in
    lib.mkMerge [
      (lib.mkIf config.vscode.enable {
        programs.vscode = {
          enable = true;
          package = pkgs.vscode;
          mutableExtensionsDir = false;

          profiles.default = {
            inherit extensions userSettings;
          };
        };
      })
      (lib.mkIf (config.vscode.enable && config.wsl.enable) {
        home.activation.vscodeWindowsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          install -Dm644 ${windowsSettingsFile} ${lib.escapeShellArg "${windowsDotfiles}/settings.json"}
          install -Dm644 ${windowsExtensionsFile} ${lib.escapeShellArg "${windowsDotfiles}/extensions.txt"}
        '';
      })
    ];
}
