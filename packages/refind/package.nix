{
  lib,
  writeShellApplication,
  writeText,
  coreutils,
  gnugrep,
  util-linux,
  efibootmgr,
  sbctl,
  refind,

  esp ? "/boot",
  extraConfig ? "",
  additionalFiles ? { },
  manageNvram ? true,
}:
let
  binaryName = "refind_x64.efi";
  label = "rEFInd Boot Manager";

  confFile = writeText "refind.conf" extraConfig;

  manifest = writeText "refind-manifest" (
    lib.concatStringsSep "\n" (
      [
        "${refind}/share/refind/${binaryName}\t${binaryName}"
        "${confFile}\trefind.conf"
      ]
      ++ lib.mapAttrsToList (dest: src: "${src}\t${dest}") additionalFiles
    )
  );
in
writeShellApplication {
  name = "refind-install";

  runtimeInputs = [
    coreutils
    gnugrep
    util-linux
    efibootmgr
    sbctl
  ];

  text = ''
    esp=${lib.escapeShellArg esp}
    manifest=${lib.escapeShellArg manifest}
    label=${lib.escapeShellArg label}
    binary=${lib.escapeShellArg binaryName}
    manage_nvram=${if manageNvram then "1" else "0"}

    refind_dir="$esp/EFI/refind"
    mkdir -p "$refind_dir"

    staged_paths=()

    while IFS=$'\t' read -r src dest; do
      [ -n "$src" ] || continue
      dest_path="$refind_dir/$dest"
      mkdir -p "$(dirname "$dest_path")"
      cp -f "$src" "$dest_path.tmp"
      mv -f "$dest_path.tmp" "$dest_path"
      staged_paths+=("$dest_path")
    done < "$manifest"

    # sbctl sign-all only re-signs already-tracked files; enroll new ones here so it picks them up.
    for path in "''${staged_paths[@]}"; do
      if ! sbctl list-files 2>/dev/null | grep -qF "$path"; then
        sbctl sign -s "$path" || true
      fi
    done

    if [ "$manage_nvram" = 1 ] && [ -d /sys/firmware/efi ]; then
      existing_line="$(efibootmgr | grep -E "^Boot[0-9A-Fa-f]{4}[*]? $label"'$' || true)"
      if [ -z "$existing_line" ]; then
        esp_partition="$(findmnt -n -o SOURCE --target "$esp")"
        esp_disk="$(lsblk -no PKNAME "$esp_partition" | head -n1)"
        esp_partnum="$(lsblk -no PARTN "$esp_partition" | head -n1)"
        if [ -n "$esp_disk" ] && [ -n "$esp_partnum" ]; then
          nvram_path="\EFI\refind\\$binary"
          efibootmgr -c -d "/dev/$esp_disk" -p "$esp_partnum" -l "$nvram_path" -L "$label" >/dev/null
        fi
      fi
    fi
  '';
}
