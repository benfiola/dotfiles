#!/bin/bash
set -e 

SUDO_USER="${SUDO_USER:-}"
if [ "$SUDO_USER" = "" ]; then
    2>&1 echo "error: must be run with sudo"
    exit 1
fi

SUDOERSD_PATH="/etc/sudoers.d"
if [ ! -e "$SUDOERSD_PATH" ]; then
    echo "creating directory: $SUDOERSD_PATH"
    mkdir -p "$SUDERSD_PATH"
fi

SUDOERSD_FILE="$SUDOERSD_PATH/$SUDO_USER"
if [ ! -e "$SUDOERSD_FILE" ]; then
    echo "creating file: $SUDOERSD_FILE"
    touch "$SUDOERSD_FILE"
fi

SUDOERSD_LINE="$SUDO_USER ALL=(ALL) NOPASSWD: ALL"

set +e
cat "$SUDOERSD_FILE" | grep -q "$SUDOERSD_LINE" 
SUDOERSD_LINE_EXISTS="$?"
set -e

if [ ! "$SUDOERSD_LINE_EXISTS" = "0" ]; then
    echo "adding line to sudoersd file: $SUDOERSD_LINE"
    echo "$SUDOERSD_LINE" >> "$SUDOERSD_FILE"
fi

exit 0
