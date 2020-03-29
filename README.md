# development-environment

Supporting utilities and provisioning files for creating a VM-based development environment.

```
./provisioning # ansible-based provisioning files used by Vagrant's ansible provisioner
./plugin # vagrant plugin that tries to keep hackery out of the Vagrantfile
```

# Install

1. Install [vagrant](https://www.vagrantup.com/downloads.html)
2. Install [virtualbox](https://www.virtualbox.org/wiki/Downloads)
3. Install [virtualbox extensions](https://www.virtualbox.org/wiki/Downloads)
4. Install [ruby](https://www.ruby-lang.org/en/documentation/installation/)
5. Install provided `vagrant-devenv` plugin (`vagrant plugin install ./plugin/vagrant-devenv.gem`)

# Usage

## Create a development environment

`vagrant devenv up <name>`

## Destroy a development environment

`vagrant devenv destroy <name>`

## List environments created through `vagrant-devenv`

`vagrant devenv status`

