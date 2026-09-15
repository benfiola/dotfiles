{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook3,
  gtk3,
  libayatana-appindicator,
  wireguard-tools,
}:

buildGoModule rec {
  pname = "wireguird";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "UnnoTed";
    repo = "wireguird";
    rev = "v${version}";
    hash = lib.fakeHash; # TODO: replace with real hash from a build attempt
  };

  vendorHash = lib.fakeHash; # TODO: replace with real hash from a build attempt

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    libayatana-appindicator
  ];

  # static/ is checked into upstream empty - wireguird.glade and Icon/ get
  # embedded into it here via fileb0x, and gui/get/gtk.go is generated from
  # a local codegen script. Both run offline against the vendored modules.
  preBuild = ''
    go generate ./...
  '';

  # wg-quick/wg aren't a build dependency, but wireguird shells out to them
  # at runtime.
  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ wireguard-tools ]})
  '';

  postInstall = ''
    install -Dm644 ${src}/deb/usr/share/applications/wireguird.desktop \
      $out/share/applications/wireguird.desktop
    install -Dm644 ${src}/deb/usr/share/polkit-1/actions/wireguird.policy \
      $out/share/polkit-1/actions/wireguird.policy
    cp -r ${src}/Icon $out/share/wireguird/Icon

    substituteInPlace $out/share/applications/wireguird.desktop \
      --replace-fail "/usr/bin/wireguird" "$out/bin/wireguird" \
      --replace-fail "/usr/share/wireguird/Icon" "$out/share/wireguird/Icon"
    substituteInPlace $out/share/polkit-1/actions/wireguird.policy \
      --replace-fail "/usr/bin/wireguird" "$out/bin/wireguird"
  '';

  meta = {
    description = "GTK GUI client for WireGuard";
    homepage = "https://github.com/UnnoTed/wireguird";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "wireguird";
  };
}
