#!/bin/sh -e

venv_list="" 

if [ -d "$PYTHON_VENV_HOME" ]; then
    venv_list="$(ls -1 --color=never "$PYTHON_VENV_HOME")" 
fi

echo "$venv_list"