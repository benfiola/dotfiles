#!/usr/bin/env sh
debug_msg() {
    if [ "$ZSHRC_DEBUG" = "" ]; then
        return
    fi
    
    message="$1"
    1>&2 echo "$message"
}

debug_msg "start: .zshrc"

if [ "$ZSHRC_PATH" = "" ]; then
    export ZSHRC_ORIGINAL_PATH="$PATH"
fi
export PATH="$ZSHRC_ORIGINAL_PATH"

export ZSHRC_PROFILED_PATH="$HOME/.profile.d"
export ZSHRC_BIN_PATH="$HOME/.bin"

if [ -d "$ZSHRC_PROFILED_PATH" ]; then
    for file in "$ZSHRC_PROFILED_PATH"/*.sh; do
        debug_msg "source: $file"
        . "$file"
    done
else
    debug_msg "$ZSHRC_PROFILED_PATH not found"
fi

if [ ! -d "$ZSHRC_BIN_PATH" ]; then
    debug_msg "$ZSHRC_BIN_PATH not found" 
fi
export PATH="$ZSHRC_BIN_PATH:$PATH"

debug_msg "end: .zshrc"

unset debug_msg

autoload -Uz compinit && compinit
