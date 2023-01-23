#!/usr/bin/python
from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
'''

EXAMPLES = r'''
'''

RETURN = r'''
'''

from ansible.module_utils.basic import AnsibleModule
import os


class ModuleFailure(Exception):
    def __init__(self, msg):
        super(ModuleFailure, self).__init__(msg)


def ensure_valid_asdf_executable(module, executable):
    rc, out, err = module.run_command([
        executable, "version"
    ])
    if rc != 0:
        raise ModuleFailure("invalid asdf executable: {executable}".format(
            executable=executable
        ))


def get_plugins(module, executable):
    rc, out, err = module.run_command([
        executable, "plugin", "list"
    ])
    if rc != 0:
        raise ModuleFailure(f"failed to get plugin list: {err}".format(
            err=err
        ))
    return out.strip().splitlines()


def install_plugin(module, executable, name):
    rc, out, err = module.run_command([
        executable, "plugin", "add", name
    ])
    if rc != 0:
        raise ModuleFailure(f"failed to install plugin {name}: {err}".format(
            name=name, 
            err=err
        ))


def uninstall_plugin(module, executable, name):
    rc, _, err = module.run_command([
        executable, "plugin", "remove", name
    ])
    if rc != 0:
        raise ModuleFailure(f"failed to uninstall plugin {name}: {err}".format(
            name=name, 
            err=err
        ))


def get_plugin_versions(module, executable, name):    
    rc, out, err = module.run_command([
        executable, "list", name
    ])
    if rc != 0:
        raise ModuleFailure(f"failed to get version list for plugin {name}: {err}".format(
            name=name, 
            err=err
        ))
    return [v.strip() for v in out.splitlines()]


def install_plugin_version(module, executable, name, version):
    rc, out, err = module.run_command([
        executable, "install", name, version
    ])
    if rc != 0:
        raise ModuleFailure(f"failed to install version {version} for plugin {name}: {err}".format(
            name=name, 
            version=version,
            err=err
        ))


def uninstall_plugin_version(module, executable, name, version):
    rc, out, err = module.run_command([
        executable, "uninstall", name, version
    ])


def get_global_tool_versions():
    to_return = {}
    global_version_file = os.path.expanduser("~/.tool-versions")
    if not os.path.exists(global_version_file):
        return to_return
    with open(global_version_file, "r") as f:
        for line in f.readlines():
            tool, version = line.split()
            to_return[tool] = version
    return to_return


def set_global_tool_version(module, executable, name, version):
    rc, out, err = module.run_command([
        executable, "global", name, version
    ])
    if rc != 0:
        raise ModuleFailure(f"failed to set global version {version} for plugin {name}: {err}".format(
            name=name, 
            version=version,
            err=err
        ))


def run_module():
    module_args = dict(
        plugin=dict(type='str', required=True),
        executable=dict(type='str', required=True),
        version=dict(type='str', required=False),
        state=dict(type='str', required=False),
        global_=dict(type='bool', required=False)
    )
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    arguments = dict(
        version=None,
        state="present",
        executable="asdf",
        global_=False
    )
    arguments.update(
        module.params
    )
    if arguments["executable"] == "asdf":
        arguments["executable"] = module.get_bin_path("asdf")

    result = dict(
        changed=False
    )

    executable = arguments["executable"]
    plugin = arguments["plugin"]
    state = arguments["state"]
    version = arguments.get("version")
    global_ = arguments.get("global_")
    
    try:
        ensure_valid_asdf_executable(module, executable)

        if state == "present":
            # install plugin if not already installed
            if plugin not in get_plugins(module, executable):
                result["changed"] = True
                if not module.check_mode:
                    install_plugin(module, executable, plugin)
            
            # install version if specified and not already installed
            if version and version not in get_plugin_versions(module, executable, plugin):
                result["changed"] = True
                if not module.check_mode:
                    install_plugin_version(module, executable, plugin, version)

            # set version as global if specified
            if version and global_ is True:
                global_versions = get_global_tool_versions()
                if global_versions.get(plugin) != version:
                    result["changed"] = True
                    if not module.check_mode:
                        set_global_tool_version(module, executable, plugin, version)
        
        elif state == "absent":
            # only uninstall version if specified
            if version: 
                if version in get_plugin_versions(module, executable, plugin):
                    result["changed"] = True
                    if not module.check_mode:
                        uninstall_plugin_version(module, executable, plugin, version)
            
            # otherwise uninstall plugin
            elif plugin in get_plugins(module, executable):
                result["changed"] = True
                if not module.check_mode:
                    uninstall_plugin(module, executable, plugin)
        
        module.exit_json(**result)
    except ModuleFailure as e:
        module.fail_json(msg=e.msg)


def main():
    run_module()


if __name__ == '__main__':
    main()
