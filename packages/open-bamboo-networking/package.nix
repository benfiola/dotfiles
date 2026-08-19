{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  curl,
  writeShellScript,
  jq,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "open-bamboo-networking";
  version = "2.1.0";

  src = fetchurl {
    url = "https://github.com/ClusterM/open-bamboo-networking/releases/download/v${finalAttrs.version}/obn-linux-x64.tar.gz";
    hash = "sha256-G/k6C9jX02MT4+I7RZVU9U6QEXxs/UALtlqscjo4IYs=";
  };

  abiVersion = "02.03.00";
  pluginVersion = "${finalAttrs.abiVersion}.99";

  sourceRoot = "obn-linux-x64/lib/v${finalAttrs.abiVersion}";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    openssl
    curl
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 libbambu_networking.so \
      "$out/lib/libbambu_networking_${finalAttrs.pluginVersion}.so"
    install -Dm755 libBambuSource.so "$out/lib/libBambuSource.so"
    install -Dm755 liblive555.so "$out/lib/liblive555.so"

    runHook postInstall
  '';

  meta = {
    description = "Open-source drop-in replacement for OrcaSlicer's proprietary Bambu network plugin";
    homepage = "https://github.com/ClusterM/open-bamboo-networking";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };

  passthru.setupScript =
    writeShellScript "open-bamboo-networking-orcaslicer-setup" ''
      plugins="$HOME/.config/OrcaSlicer/plugins"
      mkdir -p "$plugins"
      ln -sf "${finalAttrs.finalPackage}/lib/libbambu_networking_${finalAttrs.pluginVersion}.so" "$plugins/"
      ln -sf "${finalAttrs.finalPackage}/lib/libBambuSource.so" "$plugins/"

      conf="$HOME/.config/OrcaSlicer/OrcaSlicer.conf"
      if [ -f "$conf" ]; then
        ${lib.getExe jq} \
          --arg version "${finalAttrs.pluginVersion}" \
          '.app.installed_networking = true
           | .app.network_plugin_version = $version
           | .app.network_plugin_remind_later = true' \
          "$conf" > "$conf.tmp"
        mv -f "$conf.tmp" "$conf"
      fi
    '';
})
