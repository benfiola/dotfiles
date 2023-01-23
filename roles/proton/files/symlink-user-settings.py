#!/usr/bin/env python3
import logging
from pathlib import Path
import sys
from typing import Set


main_steam_folder = Path("~/.steam/steam").expanduser().resolve()
directory = Path(__file__).resolve().parent
user_settings_file = directory.joinpath("user-settings.py")
logger = logging.getLogger()


def find_steam_libraries() -> Set[Path]:
    logger.info(f"searching for steam libraries: {main_steam_folder}")
    libraries = set([main_steam_folder])
    vdf_file = main_steam_folder.joinpath("steamapps/libraryfolders.vdf")

    logger.debug(f"vdf file: {vdf_file} (exists={vdf_file.exists()})")
    vdf = ""
    if vdf_file.exists():
        vdf = vdf_file.read_text()

    for line in vdf.splitlines():
        parts = line.split("\t")
        parts = list(filter(lambda part: part, parts))
        if len(parts) != 2:
            logger.debug(f"ignoring non-kv line: {line}")
            continue

        key, value = parts[0], " ".join(parts[1:])
        key = key[1:-1]
        if key != "path":
            logger.debug(f"ignoring non-path key: {line} (key={key})")
            continue

        value = value[1:-1]
        value = Path(value)
        logger.debug(f"path found: {value} (exists={value.exists()})")
        if not value.exists():
            continue

        libraries.add(Path(value))

    logger.info(f"steam libraries: {libraries}")
    return libraries


def find_proton_folders(steam_folder: Path) -> Set[Path]:
    logger.info(
        f"searching for proton folders: {steam_folder} (exists={steam_folder.exists()})"
    )

    folders = set()
    relpaths = [
        "compatibilitytools.d",
        "steamapps/common",
    ]
    for relpath in relpaths:
        path = steam_folder.joinpath(relpath)
        logger.debug(f"searching path: {path} (exists={path.exists()})")
        if not path.exists():
            continue
        for subpath in path.iterdir():
            has_proton = subpath.joinpath("proton").exists()
            logger.debug(f"searching subpath: {subpath} (proton={has_proton})")
            if not has_proton:
                continue
            folders.add(subpath)

    logger.info(f"proton folders: {folders}")
    return folders


def symlink_user_settings(proton_folder: Path):
    logger.info(f"symlinking user settings: {proton_folder}")
    proton_user_settings_file = proton_folder.joinpath("user_settings.py")

    if proton_user_settings_file.exists():
        if not proton_user_settings_file.is_symlink():
            raise FileExistsError(proton_user_settings_file)

        target = proton_user_settings_file.readlink()
        if target != user_settings_file:
            raise FileExistsError(proton_user_settings_file)

        proton_user_settings_file.unlink()

    logger.debug(f"symlink: {proton_user_settings_file} -> {user_settings_file}")
    proton_user_settings_file.symlink_to(user_settings_file)


def configure_logging():
    log_file = Path("/tmp/symlink-user-settings.log")
    stream_handler = logging.StreamHandler()
    file_handler = logging.FileHandler(log_file)
    formatter = logging.Formatter("[%(asctime)s]: %(msg)s")
    stream_handler.setFormatter(formatter)
    file_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)
    logger.addHandler(file_handler)
    logger.setLevel(logging.DEBUG)


def main():
    logger.info("symlink user settings run started")

    logger.info(f"main steam folder: {main_steam_folder}")
    if not main_steam_folder.exists():
        raise RuntimeError(f"main steam folder not found: {main_steam_folder}")

    logger.info(f"user settings file: {user_settings_file}")
    if not user_settings_file.exists():
        raise RuntimeError(f"user setttings file not found: {user_settings_file}")

    steam_libraries = find_steam_libraries()

    proton_folders = set()
    for library in steam_libraries:
        proton_folders.update(find_proton_folders(library))

    for proton_folder in proton_folders:
        symlink_user_settings(proton_folder)


if __name__ == "__main__":
    configure_logging()
    try:
        main()
    except BaseException as e:
        logger.exception(e)
        sys.exit(1)
