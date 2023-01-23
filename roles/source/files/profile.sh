#!/usr/bin/env sh
SOURCE_DIRECTORY="$HOME/source"

src() {
    script="$ZSHRC_BIN_PATH/src"
    source "$script" "$@"
}
