"""
Custom module that functions as a no-op
"""
from ansible.module_utils.basic import AnsibleModule
import os


def run_module():
    module_args = dict()
    result = dict(changed=False)
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
