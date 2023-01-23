#!/bin/sh -e

# parse args
if [ "$#" != "2" ]; then
    1>&2 echo "usage: $0 <version> <name>"
    return 1
fi
venv_version="$1"
venv_name="$2"

# ensure venv does not exist
venv_dir="$PYTHON_VENV_HOME/$venv_name"
if [ -d "$venv_dir" ]; then
    1>&2 echo "error: venv exists: $venv_name ($venv_dir)"
    return 1
fi

# ensure asdf exists
if ! command -v asdf > /dev/null 2>&1; then
    1>&2 echo "error: asdf not found"
    return 1
fi

# determine python location
python_dir="$(asdf where python $venv_version)"
python_not_found="$?"
if [ ! "$python_not_found" = "0" ] ; then
    1>&2 echo "error: python not found: $venv_version"
    return 1
fi
python_bin="$python_dir/bin/python"

# create venv
echo "creating venv: $venv_name with python $venv_version ($venv_dir)"
mkdir -p "$PYTHON_VENV_HOME"
"$python_bin" -m venv "$venv_dir"
venv_creation_failed="$?"
if [ ! "$venv_creation_failed" = "0" ]; then
    rm -rf "$venv_dir"
fi

# activate venv
source "$venv_dir"/bin/activate