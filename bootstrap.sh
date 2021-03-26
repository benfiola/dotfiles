#!/bin/bash
set -e 

# install dependencies
sudo -S apt update
sudo -S apt install -y git ansible curl

# run prep playbook
prep_playbook="https://raw.githubusercontent.com/benfiola/development_environment/master/prep.yaml"
username="ansible"
directory="$(mktemp -d)"
# delete $directory - git clone will fail if the directory exists
rm -rf "$directory"
echo "running prep playbook"
echo "playbook: $prep_playbook"
echo "username: $username"
echo "directory: $directory"
curl -sSL "$prep_playbook" | ansible-playbook -i localhost, -c local --extra-vars "username=$username directory=$directory" /dev/stdin

# run main playbook
main_playbook="$directory/main.yaml"
inventory="$directory/inventory.yaml"
echo "running main playbook"
echo "playbook: $main_playbook"
echo "inventory: $inventory"
ansible-playbook -u ansible -i "$inventory" "$main_playbook"

# clean up if successful
sudo rm -rf "$directory"