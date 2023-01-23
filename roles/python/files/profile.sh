#!/usr/bin/env sh
export PYTHON_VENV_HOME="$HOME/.virtualenvs"

python-mkve() {
    script="$ZSHRC_BIN_PATH/python-mkve"
    . "$script" "$@"
}

python-rmve() {
    script="$ZSHRC_BIN_PATH/python-rmve"
    . "$script" "$@"
}

python-useve() {
    script="$ZSHRC_BIN_PATH/python-useve"
    . "$script" "$@"
}
