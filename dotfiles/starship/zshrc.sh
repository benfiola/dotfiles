if ! command -v starship > /dev/null 2>&1; then
    debug_msg "starship not found"
    return
fi

eval "$(starship init zsh)"
