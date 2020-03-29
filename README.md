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

I felt that a plugin is the cleanest way to isolate custom data processing and logic.  Without a plugin, all of this activity would need to be embedded directly into the `Vagrantfile` which should be primarily be concerned with defining and provisioning VMs.  Additionally, a plugin grants us access into Vagrant's internals, allowing us to provide custom functionality as well as the ability to store metadata within the Vagrant home path.

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
