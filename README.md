# development-environment

Bootstraps a development environment

# Requirements

* `ansible`
* `git`

# Configuration

Configuration is made via environment variables:

* `LOCAL=1` instructs ansible to bootstrap the local machine
* `REMOTE=<ip-address>` instructs ansible to bootstrap the machine at _<ip-address>_
* `DESKTOP_ENVIRONMENT=gnome` instructs ansible to bootstrap the machine with the _GNOME_ desktop environment (default: _kde_)

# Usage

Run the following command:

```shell
ansible-pull -U https://github.com/benfiola/development-environment.git full.yaml
```

# TODO
* Fix discord screen sharing audio (?)
* Fix KDE opening windows off-screen