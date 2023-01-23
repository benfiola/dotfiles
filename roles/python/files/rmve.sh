#!/bin/sh -e

# parse args
if [ "$#" != "1" ]; then
    1>&2 echo "usage: $0 <name>"
    return 1
fi
venv_name="$1"

# deactivate venv if venv being removed
venv_directory="$PYTHON_VENV_HOME/$venv_name"
if [ "$VIRTUAL_ENV" = "$venv_directory" ]; then
    echo "deactivating venv: $venv_name"
    deactivate
fi

# remove files
echo "removing venv: $venv_name ($venv_directory)"
rm -rf "$venv_directory"
