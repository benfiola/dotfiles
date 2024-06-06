#!/usr/bin/env zsh
if sw_vers > /dev/null 2>&1; then
    export PATH="$(brew --prefix openssh):$PATH"
    return
else
    eval "$(ssh-agent -s)"
fi
