#!/usr/bin/env python3
import argparse
import json
import os
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str)
    parser.add_argument("--list", action="store_true", default=None)
    data = vars(parser.parse_args())

    if data.get("host"):
        print(json.dumps({}))
        return
        
    if data.get("list"):
        inventory = {
            "_meta": {
                "hostvars": {

                }
            },
            "all": {
                "children": {
                    "local": {}
                }
            },
            "local": {
                "hosts": []
            }
        }  

        local_enabled = os.environ.get("LOCAL", "0") == "1"
        if local_enabled:
            inventory["local"]["hosts"].append("localhost")
            inventory["_meta"]["hostvars"]["localhost"] = {
                "ansible_connection": "local",
                "ansible_python_interpreter": sys.executable
            }
        
        print(json.dumps(inventory))
        return


if __name__ == '__main__':
    main()
