# development_environment

## Local bootstrapping

### Prerequisites

* Create a VM with a user that will run the ansible playbook

### Instructions

Run the [./bootstrap_local.sh](./bootstrap_local.sh) script.

```
curl https://raw.githubusercontent.com/benfiola/development_environment/master/bootstrap_local.sh | /bin/bash 
```

## Remote bootstrapping

### Prerequisites

* Create a VM with a user that will run the ansible playbook
* Install and enable the OpenSSH server on the VM
* Clone this repository on your host machine.

#### Windows (Powershell)

Run the [./bootstrap_remote.bat](./bootstrap_remote.bat) script.

```
./bootstrap_remote.bat
```

#### Linux/Mac

Run the [./bootstrap_remote.sh](./bootstrap_remote.sh) script.

```
./bootstrap_remote.sh
```
