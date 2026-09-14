# Dotfiles

Dotfiles expressed as a nix flake.

---

## macOS Setup (nix-darwin)

1. Create user account.
2. Install Xcode CLI Tools: `xcode-select --install`.
3. Sign in to the App Store.
4. Grant 'Full Disk Access' permissions to Terminal
5. Install Nix: `curl -fsSL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes`.
6. Clone dotfiles: `git clone https://github.com/benfiola/dotfiles ...`
7. Install age key to `/etc/age/dotfiles.key`.
8. From dotfiles directory, build derivation: `nix build '.#darwinConfigurations.bfiola-home-laptop.system'`.
9. From dotfiles directory, activate derivation: `sudo ./result/sw/bin/darwin-rebuild switch --flake '.#[hostname]'`.
10. Remove 'Full Disk Access' from Terminal, set 'Full Disk Access' for desired terminal emulator.

Subsequent rebuilds use: `sudo darwin-rebuild switch --flake [path]#[hostname]`

---

## Windows Setup (NixOS-WSL)

1. Ensure WSL2 is enabled.
2. Download the [NixOS WSL image](https://github.com/nix-community/NixOS-WSL/releases).
3. Create a NixOS WSL distribution: `wsl --install --from-file nixos.wsl --name [name]`
4. Launch the distribution.
5. Update the distribution: `sudo nix-channel --update && sudo nixos-rebuild switch`.
6. Modify the default user: set `wsl.defaultUser` to the desired username via `sudo nixos-rebuild edit`.
7. Apply changes: `sudo nixos-rebuild boot`
8. Exit then terminate distribution.
9. Restart distribution (as root) and immediately exit to apply derivation: `wsl -d [name] --user root exit`
10. Terminate distribution again.
11. Start distribution
12. Start nix shell for bootstrap commands: `sudo nix shell nixpkgs#vim nixpkgs#git --extra-experimental-features 'nix-command flakes'`
13. Clone dotfiles: `git clone https://github.com/benfiola/dotfiles ...`
14. Install age key to `/etc/age/dotfiles.key`.
15. From the dotfiles directory, activate derivation: `sudo nixos-rebuild switch --flake [path]#[hostname]`.

Subsequent rebuilds use: `sudo nixos-rebuild switch --flake [path]#[hostname]`

---

## Linux Setup (NixOS, bare metal)

The installer ISO never applies the flake directly — it is only used to partition, mount,
and produce `hardware.nix`. The flake is applied once by `nixos-install`, from a clone
living on the target disk.

### 0. Two gaps that WSL papered over, now fixed centrally

Two host-level basics were missing outside of WSL, both fixed in the NixOS branch of
`mkHomeManagerModule` in `lib.nix` so every host gets them for free:

- **Hostname.** Every NixOS host — WSL included — defaulted to nixpkgs' own `"nixos"` unless
  something set it. Nothing did. Now `networking.hostName` defaults (via `mkDefault`, so a
  host can still override it) to the host's directory name under `hosts/`.
- **`wheel` / sudo.** This one *is* WSL-specific — `nixos-wsl` grants its default user
  `wheel` membership and passwordless sudo, which nothing else does. Bare metal installed
  with only `extraGroups = [ "docker" ]` and no way to sudo. `wheel` is now added
  unconditionally alongside it.

`users.mutableUsers` is left at its default of `true`, so the account password is set with
`passwd` after the first boot rather than being declared in the flake.

### 1. Write the installer to USB

Download the [minimal ISO](https://nixos.org/download/#nixos-iso) and write it:

```bash
sudo dd if=nixos-minimal-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Boot it. It logs in as `nixos` with passwordless sudo. Get networking up
(`sudo systemctl start NetworkManager && nmtui` for wifi), then `sudo -i`.

Flakes are not enabled on the ISO by default — enable them for the whole session:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### 2. Partition, format, mount

GPT/UEFI, ESP + LVM root + swap — the same layout as `archlinux-instructions.sh`:

```bash
parted /dev/sda -- mktable gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MB -8GB
parted /dev/sda -- set 2 lvm on
parted /dev/sda -- mkpart primary linux-swap -8GB 100%

pvcreate /dev/sda2
vgcreate vg-os /dev/sda2
lvcreate -l 100%FREE -n os vg-os

mkfs.fat -F 32 -n BOOT /dev/sda1
mkfs.ext4 -L nixos /dev/vg-os/os
mkswap -L swap /dev/sda3

swapon /dev/sda3
mount /dev/vg-os/os /mnt
mount --mkdir /dev/sda1 /mnt/boot
```

### 3. Generate the hardware configuration

```bash
nixos-generate-config --root /mnt
```

This writes `/mnt/etc/nixos/{configuration.nix,hardware-configuration.nix}`. Only
`hardware-configuration.nix` is used; `configuration.nix` is a throwaway reference — the
flake replaces it.

### 4. Clone the flake onto the target disk

```bash
nix shell nixpkgs#git nixpkgs#vim
git clone https://github.com/benfiola/dotfiles /mnt/etc/dotfiles
```

Cloning into `/mnt` (not the ISO's tmpfs) means the repo survives the reboot and the
installed system can rebuild from it immediately.

### 5. Install `hardware.nix`

```bash
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/dotfiles/hosts/[hostname]/hardware.nix
```

The generated file covers filesystems, swap, initrd modules and `nixpkgs.hostPlatform`.
Nothing needs to be added for the bootloader — `lib.nix` defaults every non-WSL NixOS host to
`systemd-boot` + EFI (via `mkDefault`, so this host's `hardware.nix` can still override it, e.g.
for a legacy BIOS machine that needs GRUB instead).

### 6. Stage it — this is the step that makes the build work

```bash
cd /mnt/etc/dotfiles
git add hosts/[hostname]/hardware.nix
```

See [Flakes only see git-tracked files](#flakes-only-see-git-tracked-files) below. `git add`
is sufficient; **do not commit yet** — commit once the machine boots and the config is known
good.

### 7. Install the age key

```bash
mkdir -p /mnt/etc/age
cp [key] /mnt/etc/age/dotfiles.key
chmod 600 /mnt/etc/age/dotfiles.key
```

Secrets are decrypted at activation, not at build time — a missing key still builds and
installs fine, it just fails the agenix units at boot (wireguard tunnels, local SSH keys).
If the key is not to hand, set `wireguard.enable = false` for the host and carry on.

### 8. Install

```bash
nixos-install --flake /mnt/etc/dotfiles#[hostname]
```

It prompts for a root password at the end. Reboot, remove the USB.

### 9. First boot

Log in as `root` on a TTY (the graphical profile brings up SDDM; use `Ctrl+Alt+F2`), then:

```bash
passwd bfiola
```

### 10. Commit the hardware configuration

Now that the machine boots, from `/etc/dotfiles`:

```bash
git add hosts/[hostname]/hardware.nix
git commit -m "add [hostname] hardware configuration"
git push
```

Subsequent rebuilds use: `sudo nixos-rebuild switch --flake /etc/dotfiles#[hostname]`

---

## Flakes only see git-tracked files

When a flake lives in a git repository, Nix copies **the git tree** to the store, not the
working directory. An untracked `hardware.nix` simply does not exist as far as the build is
concerned:

```
error: getting status of '/nix/store/...-source/hosts/[hostname]/hardware.nix': No such file or directory
       To make it visible to Nix, run:
       git -C "/mnt/etc/dotfiles" add -N "hosts/[hostname]/hardware.nix"
```

Three ways out, in order of preference:

| Approach | Effect |
| --- | --- |
| `git add [file]` | Staged-but-uncommitted files **are** visible. Builds, warns `Git tree is dirty`. |
| `git add -N [file]` | Records the path only, leaves contents unstaged. Enough for Nix to see it. |
| `nix ... 'path:/mnt/etc/dotfiles#[hostname]'` | The `path:` prefix bypasses git entirely and copies the directory as-is, untracked files included. |

So the ordering problem resolves itself: **stage, build, boot, then commit.** A commit is
never a prerequisite for a build — only tracking is. This keeps a broken hardware
configuration out of the history, and keeps the eventual commit honest, since it records a
configuration that has actually booted.

The `Git tree is dirty` warning is expected during install and can be ignored. Its only real
consequence is that `self.rev` is unavailable, which nothing here uses.

---

## Hardware Configuration (NixOS)

Each NixOS host requires a `hardware.nix` file (e.g., `hosts/[hostname]/hardware.nix`), added
to the host's module list automatically by `lib.nix` when the file exists.

To regenerate it on an already-installed machine:

```bash
sudo nixos-generate-config --show-hardware-config > hosts/[hostname]/hardware.nix
```

Nothing to re-add for the bootloader — `lib.nix` supplies the `systemd-boot`/EFI default for
every non-WSL host (see [step 5](#5-install-hardwarenix) above). Only add bootloader options
here if this host needs to override that default.

---

## Debugging & Diagnostics

### nix flake check

Validate flake syntax and evaluate all outputs for errors.

**Arguments:**

- (none) — checks all outputs in the flake

**Example:**

```bash
nix flake check
```

**Why:** Catch parse errors, missing dependencies, and evaluation failures before building.

---

### nix flake metadata

Display flake metadata including input references and their resolved revisions.

**Arguments:**

- (none) — shows metadata for the current flake
- `--json` — machine-readable output

**Example:**

```bash
nix flake metadata
nix flake metadata --json | jq '.locks.nodes'
```

**Why:** Inspect pinned versions and ensure inputs resolved as expected.

---

### nix flake update

Update inputs to their latest versions (or create a fresh flake.lock).

**Arguments:**

- (none) — updates all inputs
- `<input-name>` — update only a specific input

**Example:**

```bash
nix flake update                    # Update everything
nix flake update nixpkgs            # Update only nixpkgs
```

**Why:** Pull latest packages, fixes, and security patches; or refresh a single input without full rebuild.

---

### nix build

Evaluate and build a flake output.

**Arguments:**

- `.#<output-path>` — output to build
- `--dry-run` — evaluate without actually building
- `--verbose` — show detailed build logs
- `--print-build-logs` — stream build output

**Example:**

```bash
# NixOS
nix build --dry-run '.#nixosConfigurations.bfiola-desktop-linux.config.system.build.toplevel'

# macOS (nix-darwin)
nix build --dry-run '.#darwinConfigurations.bfiola-home-laptop.system'

# Home Manager
nix build --dry-run '.#homeConfigurations.<user>.activationPackage'

# With verbose output
nix build --verbose --print-build-logs '.#nixosConfigurations.bfiola-desktop-linux.config.system.build.toplevel'
```

**Why:** Test that your configuration builds; `--dry-run` catches evaluation errors without the build cost.

---

### nix repl

Interactive REPL for evaluating and debugging flake expressions.

**Arguments:**

- (none) — starts REPL
- `:lf .` — load the local flake
- `:lf <flake-url>` — load a remote flake

**Example:**

```bash
nix repl
> :lf .
> nixosConfigurations     # or darwinConfigurations, homeConfigurations, etc
> <config>.config.system.stateVersion
```

**Why:** Interactively test expressions, inspect configuration values, and debug evaluation issues.

---

### NIX_SHOW_STATS=1

Enable statistics and detailed error messages during evaluation.

**Example:**

```bash
NIX_SHOW_STATS=1 nix flake check
NIX_SHOW_STATS=1 nix build '.#<your-config>'
```

**Why:** Identify performance bottlenecks and get clearer error messages on evaluation failures.
