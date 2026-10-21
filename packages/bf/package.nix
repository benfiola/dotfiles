{ buildGoModule }:

buildGoModule {
  pname = "bf";
  version = "0";
  src = ./.;
  vendorHash = "sha256-GV3a60b6rcK5eD7qMIqgRd+hOgTujcGhgJp4Hb9feAc=";
  subPackages = [ "cmd/bf" ];
  ldflags = [
    "-s"
    "-w"
  ];
  meta.mainProgram = "bf";
}
