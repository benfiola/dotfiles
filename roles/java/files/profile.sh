#!/usr/bin/env sh
if asdf which java > /dev/null 2>&1; then
    . $ASDF_DIR/plugins/java/set-java-home.zsh
else
    debug_msg "no asdf java versions"
    return
fi

fpath=(${ASDF_DIR}/completions $fpath)