# dotfiles

This is my personal dotfiles project and supports macOS, Ubuntu, Archlinux operating systems on arm64 and amd64 architectures (to varying degrees).

# Requirements

* `ansible`
* `git`

# Basic usage

Running the following command will fully personalize your local machine.  

```shell
LOCAL=1 ansible-pull -U https://github.com/benfiola/development-environment.git
```

# Ansible?

Generally, dotfiles projects provide a mix of static configuration and bootstrapping scripts to provision a local computing environment.  

However, I wanted to achieve the following:

* Provision a development environment from a clean, minimal, server OS image
* Support different operating systems (e.g., macOS, Ubuntu, Archlinux)
* Support different architectures (e.g., arm64, amd64)
* Support runtime configuration (e.g., install kde _or_ install gnome)
* Support various 'flavors' of personalization (e.g., only CLI tools _or_ a full-desktop environment)
* Avoid redundant work (e.g., only install VSCode if not installed _or_ generate an SSH key only if one hasn't been made)

While all of the above is scriptable, it also comes for free with [ansible](https://docs.ansible.com/ansible).  Thus, _ansible_ seemed like the right tool for the job.

# Expected outcome

When this ansible playbook is run, the following outcomes are expected:

* This git repository is copied (or symlinked) to _$HOME_/.dotfiles
* Files at _$HOME_/.bin are available on _PATH_
* Files at _$HOME_/.profile.d are sourced when terminal sessions are created
* File-based configuration is symlinked/hardlinked _from_ _$HOME_/.dotfiles _to_ their expected location (such that local configuration change leaves the repo at _$HOME_/.dotfiles in a dirty state)
* Script-based configuration is applied on every playbook execution (e.g., _gsettings_)
* All necessary, supported applications are installed
* OS, desktop environments, and applications are all configured and themed appropriately

# Configuration

Configuration is defined in the environment, and consumed via [dynamic inventory](./inventories/env.py).


| Envioronment Variable | Description |
| - | - |
| _LOCAL_ | When set to a truthy value, playbook will be applied to the local machine.  One of _LOCAL_ or _REMOTE_IP_ must be provided. |
| _REMOTE_IP_ | When set to a truthy value, playbook will be applied to the provided IP address. One of _LOCAL_ or _REMOTE_IP_ must be provided. |
| _SYMLINK_PLAYBOOK_ | When set to a truthy value, will symlink the current playbook directory to the dotfiles path (for local development). |

# Playbook

The [main playbook](./main.yaml) lists all available roles alphabetically to ensure that no roles are accidentally ignored.

[Tags](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tags.html) ultimately filter down the roles that are executed, and [role dependencies](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#using-role-dependencies) ensure that roles are executed in a topologically sorted order.

# Roles

[Roles](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html) are intended to be analogous to software libraries and often represent the installation and configuration of core functionality.  Ideally, any role should be able to be isolated and deployed to ansible-galaxy without any modification.  All roles can be found [here](./roles).

As an example of a role's functionality, the [zsh role](./roles/zsh/tasks/main.yaml) will:

* Install zsh
* Set zsh as the shell for the current user
* Install a _zshrc_ file.

The decision to create a role (versus adding to an existing role's task list) is arbitrary - but is generally a decision made on a mix of complexity (e.g., [wine](./roles/wine/tasks/main.yaml) has a lot of explicit package dependencies) or replaceability (e.g., [konsole](./roles/konsole/tasks/main.yaml) could get swapped out for another terminal emulator).

Dependencies on other roles are explicitly defined via [role dependencies](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#using-role-dependencies).  A role might depend on another role if:

* The role depends on another role's installed binary in order to install itself (e.g., [python](./roles/python/tasks/main.yaml) indirectly depends on the [asdf](./roles/asdf/tasks/main.yaml) role's binary)
* The role depends on a fact exposed by installing another role (e.g., [ls](./roles/ls/tasks/main.yaml) depends on the [user](./roles/user/tasks/main.yaml)'s fact _user_profiled_path_).  All roles depend on the [facts](./roles/facts/tasks/main.yaml) role.


# Tags

Tags are utilized to apply various levels of personalization to the target machine.  

Tags need to be composed - personalizing a machine with a graphical environment requires `minimal,graphical` tags.

| Tag Name | Description |
| - | - |
| `minimal` | installs programs and configuration required for command line interactivity |
| `graphical` | installs programs and configuration required for graphical interactivity |
| `optional` | installs programs and configuration unrelated to development |

By default, all tags (`minimal,graphical,optional`) are applied.

# Task lists

Role task lists are structured to:

* Have a common set of tags applied to all tasks within the role
* Inform the end-user when a task might be incompletely implemented
* Guarding all subsequent tasks against fall-through when incompletely implemented

As a result, role task lists often look like the following:

```yaml
---
# apply common tags
- tags: [<tag>]
  block:
    # this block only gets executed in the fall-through case
    - when: not (darwin or (linux and amd64))
      block:
        - name: unimplemented
          empty: {}
    
    # guards for one os
    - when: darwin
      block:
        - debug:
            msg: darwin
    
    # guard for an os + architecture combination
    - when: linux and amd64
      block:
        - debug:
            msg: linux + amd64 task

    # guard common tasks
    - when: darwin or (linux and amd64)
      block:
        - debug:
            msg: common task
...
```

# Custom tasks

Generally, tasks that require a bit of processing or state aren't a great fit for ansible task lists.  To avoid needlessly complex common tasks within ansible, some functionality is instead implemented as [custom ansible modules](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html).

| Task | Description |
| - | - |
| [asdf_plugin](./library/asdf_plugin.py) | Helps manage (un)installation of [asdf plugins](https://github.com/asdf-vm/asdf-plugins) |
| [empty](./library/empty.py) | No-op task - used primarily to identify 'unimplemented' paths within role implementations |
| [temp_file](./library/temp_file.py) | Creates a temp file on the target machine |
| [temp_file_cleanup](./library/temp_file_cleanup.py) | Cleans up created temp files on the target machine - _must_ be manually run before the end of the playbook run |

# Notes

* [This](./archlinux-instructions.sh) is the rough sequence of steps I go through to install arch linux from scratch.  You'll need to substitute details where necessary (i.e., device paths).  