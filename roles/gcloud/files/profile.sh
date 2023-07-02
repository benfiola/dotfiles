#!/bin/zsh -e
if sw_vers > /dev/null 2>&1; then
    completions="${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
else
    completions="/opt/google-cloud-sdk/path.zsh.inc"
fi

if [ ! -f "${completions}" ]; then
    debug_msg "no google-cloud-sdk completions found"
    return
fi 

source "${completions}"
