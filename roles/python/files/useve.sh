#!/bin/sh -e

# parse args
if [ "$#" != "1" ]; then
    1>&2 echo "usage: $0 <name>"
    return 1
fi
venv_name="$1"

# determine venv location
venv_dir="$PYTHON_VENV_HOME/$venv_name"
if [ ! -d "$venv_dir" ] || ; then
    1>&2 echo "error: venv not found: $venv_name ($venv_dir)"
    return 1
fi

# determinve venv activate script location
activate_script="$venv_dir/bin/activate"
if [ ! -f "$activate_script" ]; then
    1>&2 echo "error: activate script not found: $venv_name ($activate_script)"
    return 1
fi

# activate venv
source "$activate_script"