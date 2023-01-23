#!/usr/bin/env zsh
if ! command -v realpath > /dev/null 2>&1; then
    debug_msg "realpath not found"
    return
fi

ls_cmd="ls"
dircolors_cmd="dircolors"
if sw_vers > /dev/null 2>&1; then
    ls_cmd="gls"
    dircolors_cmd="gdircolors"
fi

for cmd in "$dircolors_cmd" "$ls_cmd"; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        debug_msg "$cmd not found"
        return
    fi
done

directory="$(dirname "$(realpath "${(%):-%x}")")"
eval "$("$dircolors_cmd" "$directory/dircolors")"
alias ls="$ls_cmd --color=auto"
