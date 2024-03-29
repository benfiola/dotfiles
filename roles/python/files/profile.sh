#!/usr/bin/env sh
python_venv_home="$HOME/.virtualenvs"

python-mkve() {
    # parse args
    if [ "$#" != "2" ]; then
        1>&2 echo "usage: $0 <version> <name>"
        1>&2 echo "usage: $0 asdf:<version> <name>"
        1>&2 echo "usage: $0 path:<python-bin-path> <name>"
        return 1
    fi
    IFS=":" read -rA venv_python_data <<< "$1"
    if [ "${#venv_python_data[@]}" = "1" ]; then
        venv_python="${venv_python_data[1]}"
        venv_python_provider="asdf"
    else
        venv_python_provider="${venv_python_data[1]}"
        venv_python="${venv_python_data[2]}"
    fi
    venv_name="$2"

    # ensure venv does not exist
    venv_dir="$python_venv_home/$venv_name"
    if [ -d "$venv_dir" ]; then
        1>&2 echo "error: venv exists: $venv_name ($venv_dir)"
        return 1
    fi

    # find venv python location
    echo "venv python provider: $venv_python_provider (python: $venv_python)"
    if [ "$venv_python_provider" = "asdf" ]; then        
        # ensure asdf exists
        if ! command -v asdf > /dev/null 2>&1; then
            1>&2 echo "error: asdf not found"
            return 1
        fi
    
        # find asdf python executable
        python_dir="$(asdf where python $venv_python)"
        python_not_found="$?"
        if [ ! "$python_not_found" = "0" ] ; then
            1>&2 echo "error: python not found: $venv_python"
            return 1
        fi
        python_bin="$python_dir/bin/python"
    elif [ "$venv_python_provider" = "path" ]; then
        # ensure explicit path exists
        if [ ! -f "$venv_python" ]; then
            1>&2 echo "error: python not found: $venv_python"
            return 1
        fi
        python_bin="$venv_python"
    else
        1>&2 echo "error: unknown venv python provider: $venv_python_provider"
        return 1
    fi

    # create venv
    echo "creating venv: $venv_name with python $venv_version ($venv_dir)"
    mkdir -p "$python_venv_home"
    "$python_bin" -m venv "$venv_dir"
    venv_creation_failed="$?"
    if [ ! "$venv_creation_failed" = "0" ]; then
        rm -rf "$venv_dir"
    fi

    # activate venv
    source "$venv_dir"/bin/activate
}

python-rmve() {
    # parse args
    if [ "$#" != "1" ]; then
        1>&2 echo "usage: $0 <name>"
        return 1
    fi
    venv_name="$1"

    # deactivate venv if venv being removed
    venv_directory="$python_venv_home/$venv_name"
    if [ "$VIRTUAL_ENV" = "$venv_directory" ]; then
        echo "deactivating venv: $venv_name"
        deactivate
    fi

    # remove files
    echo "removing venv: $venv_name ($venv_directory)"
    rm -rf "$venv_directory"
}

python-useve() {
    # parse args
    if [ "$#" != "1" ]; then
        1>&2 echo "usage: $0 <name>"
        return 1
    fi
    venv_name="$1"

    # determine venv location
    venv_dir="$python_venv_home/$venv_name"
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

python-lsve() {
    venv_list="" 

    if [ -d "$python_venv_home" ]; then
        venv_list="$(ls -1 --color=never "$python_venv_home")" 
    fi

    echo "$venv_list"
}

export PYTHON_VENV_HOME="$python_venv_home"
