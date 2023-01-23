#!/bin/bash
set -e 

USER=$(whoami)
LOCATION="/home/$USER/.development_environment"
REPO="https://github.com/benfiola/development_environment.git"

# install dependencies
sudo -S apt update
sudo -S apt install -y git ansible software-properties-common

# clone and update local development_environment repository
if [ ! -d "$LOCATION" ]
then
	git clone "$REPO" "$LOCATION"
fi
(cd "$LOCATION" && git pull origin)

# enable passwordless sudo
sudo -S /bin/bash "$LOCATION/helper_scripts/passwordless_sudo.sh"

# run ansible playbook
ansible-playbook -v -l local_vm -i "$LOCATION/ansible/inventory.yaml" "$LOCATION/ansible/playbook.yaml"
