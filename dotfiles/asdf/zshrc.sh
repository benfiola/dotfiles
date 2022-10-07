# initialize asdf
asdf_init_script="$HOME/.asdf/asdf.sh"
if [ ! -f "$asdf_init_script" ]; then
    debug_msg "asdf init script not found: $asdf_init_script"
    return
fi
. "$asdf_init_script"

# initialize asdf-java
if asdf which java > /dev/null 2>&1; then
    . $ASDF_DIR/plugins/java/set-java-home.zsh
else
    debug_msg "no asdf java versions"
fi

fpath=(${ASDF_DIR}/completions $fpath)
