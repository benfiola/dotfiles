"""
Custom module that unarchives dmg files
"""
from ansible.module_utils.basic import AnsibleModule
import contextlib
import os
import shutil
import tempfile
import time
    

@contextlib.contextmanager
def mount_dmg(module, file):
    with tempfile.TemporaryDirectory() as td:
        try:
            module.run_command(["hdiutil", "attach", "-mountpoint", td, file], check_rc=True)
            yield td            
        finally:
            time.sleep(1)
            module.run_command(["hdiutil", "detach", td], check_rc=True)


def run_module():
    module_args = dict(
        src=dict(type='str', required=True),
        remote_src=dict(type='bool', default=False),
        dest=dict(type='str', required=True),
        creates=dict(type='str', default=None)
    )

    result = dict(
        changed=False,
        data=[]
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )
    
    creates = module.params["creates"]

    if not creates or not os.path.exists(creates):
        result["changed"] = True

        src = module.params["src"]
        dest = module.params["dest"]

        with mount_dmg(module, src) as mount_point:
            for p in os.listdir(mount_point):
                src_p = os.path.join(mount_point, p)
                dest_p = os.path.join(dest, p)

                if os.path.islink(src_p):
                    continue
                
                if os.path.isdir(src_p):
                    shutil.copytree(src_p, dest_p)
                else:
                    shutil.copyfile(src_p, dest_p)
    
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
