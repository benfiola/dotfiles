"""
Custom module that creates temporary directories/files
"""
from ansible.module_utils.basic import AnsibleModule
import os
import json
import tempfile


state_file = "/tmp/ansible-temp-file.json"


def run_module():
    module_args = dict(
        prefix=dict(type='str', required=False, default=None),
        suffix=dict(type='str', required=False, default=None),
        basedir=dict(type='str', required=False, default=None),
        directory=dict(type='bool', required=False, default=False)
    )
    
    result = {
        "changed": False,
        "path": None
    }
    
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=False
    )
    
    create_directory = module.params["directory"]
    prefix = module.params["prefix"]
    suffix = module.params["suffix"]
    basedir = module.params["basedir"]
    
    temp_files = []
    if os.path.exists(state_file):
        with open(state_file, "r") as f:
            temp_files = json.loads(f.read())
    
    if module.params["directory"]:
        path = tempfile.TemporaryDirectory(
            prefix=prefix,
            suffix=suffix,
            dir=basedir
        ).name
    else:
        with tempfile.NamedTemporaryFile(
            prefix=prefix,
            suffix=suffix,
            dir=basedir,
            delete=False
        ) as f:
            path = f.name
    temp_files.append(path)
    result["path"] = path
    
    with open(state_file, "w") as f:
        f.write(json.dumps(temp_files))
    
    result["changed"] = True
    
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()


