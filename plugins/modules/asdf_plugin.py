"""
Custom module that manages asdf plugins
"""
from ansible.module_utils.basic import AnsibleModule
import os


def get_plugins(module, executable):
    _, out, _ = module.run_command([executable, "plugin", "list"])
    plugins = []
    for line in out.splitlines():
        plugins.append(line.strip())
    return plugins


def add_plugin(module, executable, plugin):
    module.run_command([executable, "plugin", "add", plugin], check_rc=True)


def remove_plugin(module, executable, plugin):
    module.run_command([executable, "plugin", "remove", plugin], check_rc=True)
    

def run_module():
    default_asdf_path = os.path.join(os.path.expandvars("$HOME"), ".asdf/bin/asdf")

    module_args = dict(
        name=dict(type='str', required=True),
        state=dict(type='str', default="present", choices=["absent", "present"]),
        executable=dict(type='str', default=default_asdf_path)
    )

    result = dict(
        changed=False
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    state = module.params["state"]
    name = module.params["name"]
    executable = module.params["executable"]

    if not os.path.exists(executable):
        raise ValueError(f"asdf not found: %s" % executable)
    
    if state == "present":
        if name not in get_plugins(module, executable):
            result["changed"] = True
            add_plugin(module, executable, name)
    if state == "absent":
        if name in get_plugins(module, executable):
            result["changed"] = True
            remove_plugin(module, executable, name)

    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
