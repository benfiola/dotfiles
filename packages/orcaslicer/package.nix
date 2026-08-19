{
  lib,
  symlinkJoin,
  makeWrapper,
  orca-slicer,
  callPackage,
}:
let
  networkPlugin = callPackage ../open-bamboo-networking/package.nix { };
in
symlinkJoin {
  name = "orca-slicer-obn";
  paths = [ orca-slicer ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/orca-slicer --run "${networkPlugin.setupScript}"
  '';

  meta = {
    description = "OrcaSlicer wrapped with the open-source Bambu network plugin";
    mainProgram = "orca-slicer";
    platforms = lib.platforms.linux;
  };
}
