#!/bin/sh -e

if [ ! -d "$SOURCE_DIRECTORY" ]; then
    mkdir -p "$SOURCE_DIRECTORY"
fi

cd "$SOURCE_DIRECTORY"
