#!/bin/bash
set -e 

cwd="$(pwd)"
directory="$(mktemp -d)"
main_playbook="$directory/main.yaml"
repo_url="https://github.com/benfiola/development_environment.git"

cleanup() {
    if [ -d "$directory" ]; then
        rm -rf "$directory"
    fi
    cd "$cwd"
}
trap "cleanup" exit;

# install dependencies
echo "installing dependencies"
sudo -S apt-get -y update > /dev/null
sudo -S apt-get -y install git ansible curl > /dev/null

# clone repository
echo "cloning $repo_url -> $directory"
rm -rf "$directory"
git clone -q "$repo_url" "$directory" > /dev/null

# ensure main playbook exists
if [ ! -f "$main_playbook" ]; then
    1>&2 echo "error: file not found: $main_playbook"
    exit 1
fi

# run playbook
echo "running playbook: $main_playbook"
cd "$directory"
ansible-playbook "$main_playbook"
