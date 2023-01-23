#!/usr/bin/env sh
asdf_init_script="$HOME/.asdf/asdf.sh"
if [ ! -f "$asdf_init_script" ]; then
    debug_msg "asdf init script not found: $asdf_init_script"
    return
fi
. "$asdf_init_script"
