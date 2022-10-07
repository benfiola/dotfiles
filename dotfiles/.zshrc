
debug_msg() {
    if [ "$ZSHRC_DEBUG" = "" ]; then
        return
    fi
    
    message="$1"
    1>&2 echo "$message"
}

directory="$(dirname "${(%):-%x}")"
for file in $(find "$directory" -maxdepth 4 -name zshrc.sh); do
    debug_msg "initialize: $file"
    . "$file"
done

unset debug_msg

autoload -Uz compinit && compinit
