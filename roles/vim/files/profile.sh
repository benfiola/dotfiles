#!/usr/bin/env sh
if ! command -v vim > /dev/null 2>&1; then
    debug_msg "vim not found"
    return
fi

export EDITOR=vim
