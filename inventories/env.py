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
                    "machine": {},
                }
            },
            "machine": {
                "hosts": []
            }
        }  

        hostvars = {}
        desktop_environment = os.environ.get("DESKTOP_ENVIRONMENT")
        if desktop_environment:
            hostvars["desktop_environment"] = desktop_environment
        
        host = None

        is_localhost = os.environ.get("LOCAL", "0") == "1"
        remote_ip = os.environ.get("REMOTE")

        if not is_localhost and not remote_ip:
            print(json.dumps(inventory))
            return
        
        if is_localhost:
            host = "localhost"
            hostvars = {
                **hostvars,
                "ansible_connection": "local",
                "ansible_python_interpreter": sys.executable
            }
        else:
            host = remote_ip
            hostvars = {**hostvars}

        inventory["machine"]["hosts"].append(host)
        inventory["_meta"]["hostvars"][host] = hostvars
        
        print(json.dumps(inventory))
        return


if __name__ == '__main__':
    main()
