# development-environment

Supporting utilities and provisioning files for creating a VM-based development environment.

```
./provisioning # ansible-based provisioning files used by Vagrant's ansible provisioner
./plugin # vagrant plugin that tries to keep hackery out of the Vagrantfile
```

While this is generally designed to accommodate my personal tastes and desired configuration, this repository is straightforward enough to be forked and customized to suit your needs quickly.

# Usage

## Create a development environment

`vagrant devenv up <name>`

## Destroy a development environment

`vagrant devenv destroy <name>`

## List development environments

`vagrant devenv status`

# Install

1. Install [vagrant](https://www.vagrantup.com/downloads.html)
2. Install [virtualbox](https://www.virtualbox.org/wiki/Downloads)
3. Install [virtualbox extensions](https://www.virtualbox.org/wiki/Downloads)
4. Install provided `vagrant-devenv` plugin (`vagrant plugin install ./plugin/vagrant-devenv-0.0.1.gem`)

# Plugin

While you can run `vagrant up` directly (and receive a `default` VM), using the provided plugin turns the `Vagrantfile` into a template capable of generating different named VMs.

Sure, this could have been done by adding hooks into the `Vagrantfile`, but I've found this approach to be messy and brittle.  Plus, having access to Vagrant's internals makes it easier to add additional functionality in the future. 

## Development

1.  Install [ruby](https://www.ruby-lang.org/en/downloads/releases/)
2.  Run `bundle install` from `plugin` directory to install dependencies.
3.  Run `bundle exec vagrant devenv <subcommand>` to test plugin
4.  Run `gem build vagrant-devenv.gemspec` to build plugin.

### RubyMine Run Configuration

* Gem Command
  * Gem name: vagrant
  * Executable name: vagrant
  * Arguments: devenv <subcommand>
  * `Bundler` -> `Run the script in context of the bundle (bundle exec)`
