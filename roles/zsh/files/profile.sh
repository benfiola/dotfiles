#!/usr/bin/env sh
debug_msg() {
    if [ "$ZSHRC_DEBUG" = "" ]; then
        return
    fi
    
    message="$1"
    1>&2 echo "$message"
}

debug_msg "start: .zshrc"

export ZSHRC_PROFILED_PATH="$HOME/.profile.d"
if [ -d "$ZSHRC_PROFILED_PATH" ]; then
    for file in "$ZSHRC_PROFILED_PATH"/*.sh; do
        debug_msg "source: $file"
        . "$file"
    done
else
    debug_msg "$ZSHRC_PROFILED_PATH not found"
fi

debug_msg "end: .zshrc"

unset debug_msg

autoload -Uz compinit && compinit
