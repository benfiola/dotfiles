# chromium

## Usage

### Linux

```
ln <directory>/policy.json /etc/chromium-browser/policies/managed/
```

### MacOS

#### Creation

MacOS policies are defined from `.mobileconfig` files that we can generate using the [policy.json](./policy.json) file.

```
/usr/bin/python3 <directory>/create_macos_policy.py
```

#### Installation

```
profiles -R -F <directory>/macos.mobileconfig
open <directory>/macos.mobileconfig
```

NOTE: There is no way to detect whether this mobile configuration is already installed and can be installed multiple times.  Thus, the mobile configuration should be removed prior to being re-installed.