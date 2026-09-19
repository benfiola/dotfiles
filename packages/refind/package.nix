{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  writeText,
  util-linux,
  efibootmgr,
  sbctl,
  refind,

  esp ? "/boot",
  extraConfig ? "",
  additionalFiles ? { },
  additionalDirs ? { },
  manageNvram ? true,
}:
let
  binaryName = "refind_x64.efi";
  label = "rEFInd Boot Manager";

  confFile = writeText "refind.conf" (
    builtins.readFile "${refind}/share/refind/refind.conf-sample"
    + lib.optionalString (extraConfig != "") ''

      # --- overrides below ---
      ${extraConfig}
    ''
  );

  files = [
    [
      "${refind}/share/refind/${binaryName}"
      binaryName
    ]
    [
      "${confFile}"
      "refind.conf"
    ]
  ]
  ++ lib.mapAttrsToList (dest: src: [
    "${src}"
    dest
  ]) additionalFiles;

  dirs = lib.mapAttrsToList (dest: src: [
    "${src}"
    dest
  ]) additionalDirs;

  configFile = writeText "refind-install-config.json" (
    builtins.toJSON {
      inherit
        esp
        label
        files
        dirs
        ;
      binary = binaryName;
      manage_nvram = manageNvram;
    }
  );
in
stdenvNoCC.mkDerivation {
  pname = "refind-install";
  version = "0";

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  meta.mainProgram = "refind-install";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    makeWrapper ${python3}/bin/python3 $out/bin/refind-install \
      --add-flags ${./refind-install.py} \
      --set REFIND_INSTALL_CONFIG ${configFile} \
      --prefix PATH : ${
        lib.makeBinPath [
          efibootmgr
          sbctl
          util-linux
        ]
      }
    runHook postInstall
  '';
}
