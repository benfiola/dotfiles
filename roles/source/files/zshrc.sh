#!/usr/bin/env sh
directory="$HOME/source"

if [ ! -d "$directory" ]; then
    mkdir -p "$directory"
fi

alias src="cd ~/source"
