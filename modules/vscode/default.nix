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
      (lib.mkIf config.wsl {
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
    in
    lib.mkIf config.vscode.enable {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;
        mutableExtensionsDir = false;

        profiles.default = {
          extensions = [
            marketplace.anthropic.claude-code
            marketplace.arcticicestudio.nord-visual-studio-code
            marketplace.esbenp.prettier-vscode
            marketplace.ms-azuretools.vscode-containers
            marketplace.ms-vscode-remote.remote-containers
            marketplace.pkief.material-icon-theme
            marketplace.rohit-gohri.format-code-action
            marketplace.usernamehw.errorlens
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
        };
      };
    };
}
