#!/usr/bin/env sh
debug_msg() {
    if [ "$ZSHRC_DEBUG" = "" ]; then
        return
    fi
    
    message="$1"
    1>&2 echo "$message"
}

profiled_dir="$HOME/.profile.d"
if [ -d "$profiled_dir" ]; then
    for file in "$profiled_dir"/*.sh; do
        debug_msg "initialize: $file"
        . "$file"
    done
else
    debug_msg "$profiled_dir not found"
fi

bin_dir="$HOME/.bin"
if [ -d "$bin_dir" ]; then
    export PATH="$bin_dir:$PATH"
else
    debug_msg "$bin_dir not found" 
fi

unset debug_msg

autoload -Uz compinit && compinit
