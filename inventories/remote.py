#!/usr/bin/env python3
import argparse
import json
import os


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
                    "remote": {}
                }
            },
            "remote": {
                "hosts": []
            }
        }  

        remote_ip = os.environ.get("REMOTE")
        if remote_ip:
            inventory["remote"]["hosts"].append(remote_ip)
            inventory["_meta"]["hostvars"][remote_ip] = {}
        
        print(json.dumps(inventory))
        return


if __name__ == '__main__':
    main()
