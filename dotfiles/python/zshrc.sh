_python_alias_venv_home="$HOME/.virtualenvs"

mkpyve() {
    # parse args
    if [ "$#" != "2" ]; then
        1>&2 echo "usage: $0 <version> <name>"
        return 1
    fi
    venv_version="$1"
    venv_name="$2"

    # ensure venv does not exist
    venv_dir="$_python_alias_venv_home/$venv_name"
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
    mkdir -p "$_python_alias_venv_home"
    "$python_bin" -m venv "$venv_dir"
    venv_creation_failed="$?"
    if [ ! "$venv_creation_failed" = "0" ]; then
        rm -rf "$venv_dir"
    fi

    # activate venv
    source "$venv_dir"/bin/activate
}

rmpyve() {
    # parse args
    if [ "$#" != "1" ]; then
        1>&2 echo "usage: $0 <name>"
        return 1
    fi
    venv_name="$1"
    
    # deactivate venv if venv being removed
    venv_directory="$_python_alias_venv_home/$venv_name"
    if [ "$VIRTUAL_ENV" = "$venv_directory" ]; then
        echo "deactivating venv: $venv_name"
        deactivate
    fi

    # remove files
    echo "removing venv: $venv_name ($venv_directory)"
    rm -rf "$venv_directory"
}

lspyve() {
    venv_list="" 

	if [ -d "$_python_alias_venv_home" ]; then
		venv_list="$(ls -1 --color=never "$_python_alias_venv_home")" 
	fi

	echo "$venv_list"
}

usepyve() {
    # parse args
    if [ "$#" != "1" ]; then
        1>&2 echo "usage: $0 <name>"
        return 1
    fi
    venv_name="$1"

    # determine venv location
    venv_dir="$_python_alias_venv_home/$venv_name"
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
}