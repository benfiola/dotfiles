"""
Custom module that cleans up any directories created by the `temp_file` module.

Intended to always be run at the end of a playbook.
"""
from ansible.module_utils.basic import AnsibleModule
import os
import json
import shutil
import tempfile


state_file = "/tmp/ansible-temp-file.json"


def run_module():
    module_args = dict()

    result = dict(
        changed=False,
        paths=[]
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=False
    )
    
    temp_files = []
    if os.path.exists(state_file):
        with open(state_file, "r") as f:
            temp_files = json.loads(f.read())
    
    if not temp_files:
        module.exit_json(**result)
        return
    
    while temp_files:
        temp_file = temp_files.pop()
        
        if os.path.exists(temp_file):
            result["changed"] = True
            
            if os.path.isdir(temp_file):
                shutil.rmtree(temp_file)
            else:
                os.unlink(temp_file)
                
            result["paths"].append(temp_file)
        
        with open(state_file, "w") as f:
            f.write(json.dumps(temp_files))
    
    os.unlink(state_file)
    
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()


