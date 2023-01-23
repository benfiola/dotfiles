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
    export ZSHRC_PATH="$PATH"
fi
export PATH="$ZSHRC_PATH"

profiled_dir="$HOME/.profile.d"
if [ -d "$profiled_dir" ]; then
    for file in "$profiled_dir"/*.sh; do
        debug_msg "source: $file"
        . "$file"
    done
else
    debug_msg "$profiled_dir not found"
fi

bin_dir="$HOME/.bin"
if [ ! -d "$bin_dir" ]; then
    debug_msg "$bin_dir not found" 
fi
export ZSHRC_BIN_DIR="$bin_dir"
export PATH="$bin_dir:$PATH"

debug_msg "end: .zshrc"

unset debug_msg

autoload -Uz compinit && compinit
