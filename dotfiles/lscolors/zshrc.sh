directory="$(dirname "${(%):-%x}")"

ls_bin="ls"
dircolors_bin="dircolors"
if sw_vers > /dev/null 2>&1; then
    dircolors_bin="gdircolors"
    ls_bin="gls"
fi

for bin in $ls_bin $dircolors_bin; do
    if ! command -v "$bin" > /dev/null 2>&1; then
        debug_msg "$bin not found"
        return
    fi
done

eval "$("$dircolors_bin" "$directory/dircolors")"
alias ls="$ls_bin --color"
