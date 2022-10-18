"""
Custom module that unarchives dmg files
"""
from ansible.module_utils.basic import AnsibleModule
import contextlib
import os
import shutil
import tempfile
import time
from urllib.parse import urlparse
    

@contextlib.contextmanager
def mount_dmg(module, file):
    with tempfile.TemporaryDirectory() as td, tempfile.NamedTemporaryFile(suffix=".dmg") as tf:
        try:
            if urlparse(file).hostname:
                module.run_command(["curl", "-L", "-o", tf.name, file])
                file = tf.name

            module.run_command(["hdiutil", "attach", "-noautoopen", "-mountpoint", td, file], check_rc=True)
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
            module.run_command(["cp", "-R", "{0}/".format(mount_point), dest], check_rc=True)
    
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
 