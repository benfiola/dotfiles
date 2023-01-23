#!/usr/bin/env python
import json
import os
import plistlib
import sys
import tempfile

import mcxToProfile


uuid = "e2dab085-1c2d-4a4d-a7b9-e410e66446cc"


def main():
    directory = os.path.dirname(__file__)
    policy_file = os.path.join(directory, "policy.json")
    mobileconfig_file = os.path.join(directory, "macos.mobileconfig")
    
    with tempfile.TemporaryDirectory() as directory:
        profile = os.path.join(directory, "profile.plist")
        with open(profile, "w") as f:
            data = {
                "PayloadIdentifier": "com.google.Chrome",
                "PayloadUUID": uuid
            }
            f.write(plistlib.dumps(data).decode("utf-8"))
        
        plist = os.path.join(directory, "com.google.Chrome.plist")
        with open(plist, "w") as w, open(policy_file, "r") as r:
            data = json.loads(r.read())
            w.write(plistlib.dumps(data).decode("utf-8"))
        
        sys.argv[1:] = ["--plist", plist, "--identifier-from-profile", profile, "--displayname", "development-environment: chromium", "--removal-allowed", "--output", mobileconfig_file]
        mcxToProfile.main()


if __name__ == "__main__":
    main()
