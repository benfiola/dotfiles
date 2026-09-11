{
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
      marketplace = inputs.nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
    in
    lib.mkIf config.vscode.enable {
      programs.vscode = {
        enable = true;
        package = pkgs.vscode;
        mutableExtensionsDir = false;

        profiles.default = {
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
