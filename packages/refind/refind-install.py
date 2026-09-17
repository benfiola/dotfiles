#!/usr/bin/env python3
"""Stage rEFInd's binary/config/theme onto the ESP and manage its NVRAM boot entry.

Configuration is read from the JSON file at $REFIND_INSTALL_CONFIG. See
package.nix for the fields it provides.
"""
import json
import logging
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

logging.basicConfig(
    level=logging.INFO, format="[refind-install] %(message)s", stream=sys.stderr
)
log = logging.getLogger()
BOOT_ENTRY_RE = re.compile(r"^Boot([0-9A-Fa-f]{4})\*?\s+[^\t]*\t(.*)$")


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def stage_files(refind_dir, files):
    staged = []
    refind_dir.mkdir(parents=True, exist_ok=True)
    for src, dest in files:
        dest_path = refind_dir / dest
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        tmp_path = dest_path.with_name(dest_path.name + ".tmp")
        shutil.copy2(src, tmp_path)
        os.replace(tmp_path, dest_path)
        staged.append(dest_path)
    return staged


def stage_dirs(refind_dir, dirs):
    for src, dest in dirs:
        dest_path = refind_dir / dest
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        if dest_path.exists():
            shutil.rmtree(dest_path)
        shutil.copytree(src, dest_path)


def sign_efi_files(staged):
    result = run(["sbctl", "list-files"])
    tracked_output = result.stdout if result.returncode == 0 else ""
    if result.returncode != 0:
        log.warning(
            "sbctl list-files failed (exit %s): %s",
            result.returncode,
            result.stderr.strip(),
        )

    for path in staged:
        if path.suffix.lower() != ".efi":
            continue
        if str(path) in tracked_output:
            continue
        result = run(["sbctl", "sign", "-s", str(path)])
        if result.returncode != 0:
            log.warning(
                "sbctl sign failed for %s (exit %s): %s",
                path,
                result.returncode,
                result.stderr.strip(),
            )


def matching_entry_ids(target_path):
    result = run(["efibootmgr"])
    target = target_path.lower()
    ids = []
    for line in result.stdout.splitlines():
        m = BOOT_ENTRY_RE.match(line)
        if m and target in m.group(2).lower():
            ids.append(m.group(1))
    return ids


def create_entry(esp, label, nvram_path):
    esp_partition = run(
        ["findmnt", "-n", "-o", "SOURCE", "--target", str(esp)]
    ).stdout.strip()
    disk_lines = run(["lsblk", "-no", "PKNAME", esp_partition]).stdout.split()
    partnum_lines = run(["lsblk", "-no", "PARTN", esp_partition]).stdout.split()
    esp_disk = disk_lines[0] if disk_lines else ""
    esp_partnum = partnum_lines[0] if partnum_lines else ""
    if not (esp_disk and esp_partnum):
        log.warning(
            "could not resolve esp disk/partition for %s, skipping creation", esp
        )
        return False

    result = run(
        [
            "efibootmgr",
            "-c",
            "-d",
            "/dev/" + esp_disk,
            "-p",
            esp_partnum,
            "-l",
            nvram_path,
            "-L",
            label,
        ]
    )
    if result.returncode != 0:
        log.warning(
            "efibootmgr -c failed (exit %s): %s",
            result.returncode,
            result.stderr.strip(),
        )
        return False
    return True


def manage_nvram(esp, label, binary):
    if not Path("/sys/firmware/efi").is_dir():
        return

    nvram_path = "\\EFI\\refind\\" + binary

    ids = matching_entry_ids(nvram_path)

    if len(ids) > 1:
        for entry_id in ids:
            result = run(["efibootmgr", "-b", entry_id, "-B"])
            if result.returncode != 0:
                log.warning(
                    "failed to delete Boot%s (exit %s): %s",
                    entry_id,
                    result.returncode,
                    result.stderr.strip(),
                )
        ids = []

    if ids:
        log.info("NVRAM entry already present, nothing added")
    else:
        added = create_entry(esp, label, nvram_path)
        log.info("NVRAM entry added" if added else "NVRAM entry NOT added, see warnings above")


def main():
    config = json.loads(Path(os.environ["REFIND_INSTALL_CONFIG"]).read_text())
    esp = Path(config["esp"])
    refind_dir = esp / "EFI" / "refind"

    staged = stage_files(refind_dir, config["files"])
    stage_dirs(refind_dir, config["dirs"])
    sign_efi_files(staged)
    if config["manage_nvram"]:
        manage_nvram(esp, config["label"], config["binary"])


if __name__ == "__main__":
    main()
