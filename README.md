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
12. Start nix shell for bootstrap commands: `nix shell nixpkgs#vim nixpkgs#git --extra-experimental-features 'nix-command flakes'`
13. Clone dotfiles: `git clone https://github.com/benfiola/dotfiles ...`
14. Install age key to `/etc/age/dotfiles.key`.
15. From the dotfiles directory, activate derivation: `sudo nixos-rebuild switch --flake .#[hostname]`.

Subsequent rebuilds use: `sudo nixos-rebuild switch --flake [path]#[hostname]`

---

## Linux Setup (NixOS)

<!-- prettier-ignore -->
1. Create install media via the [NixOS minimal ISO](https://nixos.org/download/#nixos-iso).
2. Boot into install media.
3. Enable experimental features for the session: `export NIX_CONFIG="experimental-features = nix-command flakes"`.
4. Start nix shell for bootstrap commands: `sudo nix shell nixpkgs#vim nixpkgs#git nixpkgs#sbctl`
5. Create and mount partitions
   ```
   parted [device]
   > mktable gpt
   > mkpart ESP fat32 0% 1024MiB
   > set 1 esp on
   > mkpart primary 1024MiB -[ram-size]GiB
   > set 2 lvm on
   > mkpart primary linux-swap -[ram-size]GiB 100%
   > quit

   pvcreate [part-lvm]
   vgcreate vg-os [part-lvm]
   lvcreate -l 100%FREE -n os vg-os

   mkfs.fat -F 32 -n BOOT [part-esp]
   mkfs.ext4 -L nixos /dev/vg-os/os
   mkswap -L swap [part-swap]

   swapon [part-swap]
   mount /dev/vg-os/os /mnt
   mount --mkdir [part-esp] /mnt/boot
   ```
6. Clone dotfiles: `git clone https://github.com/benfiola/dotfiles /mnt/etc/dotfiles`
7. Install age key to `/mnt/etc/age/dotfiles.key`.
8. Generate hardware configuration:
   ```
   nixos-generate-config --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/dotfiles/hosts/[hostname]/hardware.nix
   ```
9. Generate the secure boot keys:
   ```
   mkdir -p /mnt/var/lib/sbctl /var/lib/sbctl
   mount --bind /mnt/var/lib/sbctl /var/lib/sbctl
   sbctl create-keys
   umount /var/lib/sbctl
   ```
10. From the dotfiles directory, stage the hardware configuration: `git add -A`
11. From the dotfiles directory, install NixOS: `nixos-install --flake .#[hostname] --no-root-passwd`
12. Set the user password: `nixos-enter --root /mnt -c 'passwd [user]'`
13. Boot into UEFI, disable secure boot and clear existing secure boot keys
14. Reboot into new installation
15. Enroll secure boot keys: `nix shell nixpkgs#sbctl -c sudo sbctl enroll-keys --microsoft`.
16. Relocate dotfiles directory, and ensure its owned by the desired user/group.
17. Commit host hardware configuration.
18. Reboot into UEFI, enable secure boot
19. Boot into new installation.

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
