{ lib, buildGoModule }:

buildGoModule {
  pname = "wireguard-tray";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      ./main.go
      ./icon.png
    ];
  };

  vendorHash = "sha256-Y5s5X3mqsJ36oX3/MhK6w9Zn13MUyeonBHtV7sVwT74=";

  env.CGO_ENABLED = 0;

  meta = {
    description = "Minimal system tray toggle for wg-quick tunnels";
    platforms = lib.platforms.linux;
    mainProgram = "wireguard";
  };
}
