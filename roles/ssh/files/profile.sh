#!/usr/bin/env zsh
if ! sw_vers > /dev/null 2>&1; then
    debug_msg "not macos"
    return
fi

export PATH="$(brew --prefix openssh):$PATH"
