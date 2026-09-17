{
  lib,
  stdenvNoCC,
  fetchFromGitHub,

  iconSize ? "128-48",
  dark ? false,
}:
let
  sizes = {
    "128-48" = {
      big = "128";
      small = "48";
    };
    "256-96" = {
      big = "256";
      small = "96";
    };
    "384-144" = {
      big = "384";
      small = "144";
    };
    "512-192" = {
      big = "512";
      small = "192";
    };
  };
  size =
    sizes.${iconSize}
      or (throw "refind-theme-regular: iconSize must be one of ${toString (lib.attrNames sizes)}");
  suffix = lib.optionalString dark "_dark";
in
stdenvNoCC.mkDerivation {
  pname = "refind-theme-regular";
  version = "0-unstable-2026-08-02";

  src = fetchFromGitHub {
    owner = "bobafetthotmail";
    repo = "refind-theme-regular";
    rev = "ed76f1e6d1bfe790ea7333fe5886fa7af126475d";
    hash = "sha256-Qo3/Y1ga1/+joasXilr56lBnc1WUjd1Kubv647pt/qQ=";
  };

  dontConfigure = true;
  dontBuild = true;

  # mirrors the uncommenting that upstream's install.sh does to src/theme.conf
  # for the chosen icon size and light/dark variant
  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r fonts "$out/fonts"
    cp -r icons "$out/icons"

    sed \
      -e "s|#icons_dir themes/refind-theme-regular/icons/${size.big}-${size.small}$|icons_dir themes/refind-theme-regular/icons/${size.big}-${size.small}|" \
      -e "s|#big_icon_size ${size.big}$|big_icon_size ${size.big}|" \
      -e "s|#small_icon_size ${size.small}$|small_icon_size ${size.small}|" \
      -e "s|#banner themes/refind-theme-regular/icons/${size.big}-${size.small}/bg${suffix}.png$|banner themes/refind-theme-regular/icons/${size.big}-${size.small}/bg${suffix}.png|" \
      -e "s|#selection_big themes/refind-theme-regular/icons/${size.big}-${size.small}/selection${suffix}-big.png$|selection_big themes/refind-theme-regular/icons/${size.big}-${size.small}/selection${suffix}-big.png|" \
      -e "s|#selection_small themes/refind-theme-regular/icons/${size.big}-${size.small}/selection${suffix}-small.png$|selection_small themes/refind-theme-regular/icons/${size.big}-${size.small}/selection${suffix}-small.png|" \
      src/theme.conf > "$out/theme.conf"

    runHook postInstall
  '';

  meta = {
    description = "Regular rEFInd theme by Munlik (${iconSize}, ${if dark then "dark" else "light"})";
    homepage = "https://github.com/bobafetthotmail/refind-theme-regular";
    license = [
      lib.licenses.agpl3Plus
      lib.licenses.ofl
    ];
    platforms = lib.platforms.all;
  };
}
