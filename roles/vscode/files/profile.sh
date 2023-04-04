#!/bin/zsh -e
vscode-init() {
    # ensure jq exists
    if ! command -v jq > /dev/null 2>&1; then
        1>&2 echo "error: jq not found"
        return 1
    fi

    # create .vscode directory
    mkdir -p .vscode

    # create .vscode/settings.json file
    read -r -d '' settings_json <<EOF
{
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[jsonc]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "editor.codeActionsOnSave": [
        "source.organizeImports",
        "source.formatDocument"
    ]
}
EOF
    jq -n --argjson settings "${settings_json}" '$settings' > .vscode/settings.json

    # create .vscode/launch.json file
    read -r -d '' launch_json <<EOF
{
    "version": "0.2.0",
    "configurations": []
}
EOF
    jq -n --argjson launch "${launch_json}" '$launch' > .vscode/launch.json
}

vscode-init-py() {
    if [ "$#" != "1" ]; then
        1>&2 echo "usage: $0 <venv_name>"
        return 1
    fi
    venv_name="$1"

    vscode-init

    # ensure jq exists
    if ! command -v jq > /dev/null 2>&1; then
        1>&2 echo "error: jq not found"
        return 1
    fi

    # merge new settings on top of existing .vscode/settings.json file
    venv_dir="${PYTHON_VENV_HOME}/${venv_name}"
    interpreter="${venv_dir}/bin/python"
    read -r -d '' settings_json <<EOF
{
    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter"
    },
    "python.defaultInterpreterPath": "${interpreter}"
}
EOF
    jq -n --argjson existing "$(cat .vscode/settings.json)" --argjson new "${settings_json}" '$existing + $new' > .vscode/settings.json

    # create test.py file
    read -r -d '' test_file <<'EOF'
def main():
    pass


if __name__ == "__main__":
    main()
EOF
    echo "${test_file}" > test.py

    # merge new launch configuration on top of existing .vscode/launch.json file
    read -r -d '' launch_json <<'EOF'
{
  "configurations": [
    {
      "name": "Python: ${workspaceFolder}/test.py",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/test.py",
      "cwd": "${workspaceFolder}",
      "console": "internalConsole",
      "purpose": ["debug-in-terminal"],
      "justMyCode": false
    }
  ]
}
EOF
    jq -n --argjson existing "$(cat .vscode/launch.json)" --argjson new "${launch_json}" '$existing + $new' > .vscode/launch.json
}
