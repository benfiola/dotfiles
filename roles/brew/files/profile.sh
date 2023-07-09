#!/usr/bin/env sh

if ! sw_vers > /dev/null 2>&1; then
    # set linux path
    brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
else
    # set darwin path (arm64/amd64)
    brew_path="/usr/local/bin/brew"
    _arch="$(arch)"
    if [ "$_arch" = "arm64" ]; then
        brew_path="/opt/homebrew/bin/brew"
    fi
fi

if [ ! -f "$brew_path" ]; then
    debug_msg "brew not found: $brew_path"
    return
fi

eval "$("$brew_path" shellenv)"
