#!/bin/sh
USER=$(whoami)
LOCATION="/home/$USER/.development_environment"
REPO="https://github.com/benfiola/development_environment.git"

# update apt cache
sudo apt update

# install and check out development_environment files
if [ ! -d "$LOCATION" ]
then
	sudo apt install -y git
	git clone "$REPO" "$LOCATION"
fi

# update repo
(cd "$LOCATION" && git pull origin)

# install ansible
sudo apt install -y ansible software-properties-common

# run ansible playbook
ansible-playbook -v "$LOCATION/provisioning/playbook.yml"
