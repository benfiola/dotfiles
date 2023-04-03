#!/bin/zsh -e
completions="${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
if [ ! -f "${completions}" ]; then
    debug_msg "no google-cloud-sdk completions found"
    return
fi 
source "${completions}"
