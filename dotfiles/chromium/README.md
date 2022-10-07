# chromium

Chromium policies are used to pre-configure Chromium (and Google Chrome) with desired extensions and settings.

On Linux machines, [policy.json](./policy.json) is loaded directly from Google Chrome/Chromium.

On MacOS machines, the policy is loaded by installing a `.mobileconfig` profile.  To create this `.mobileconfig` file, run the following on a MacOS machine:

```shell
/usr/bin/python3 create_macos_policy.py
```
