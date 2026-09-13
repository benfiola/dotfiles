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
5. Enable flakes for bootstrap commands: `sudo nix shell nixpkgs#vim --command vim /etc/nix/nix.conf` and add `experimental-features = nix-command flakes`.
6. Install age key to `/etc/age/dotfiles.key`.
7. Clone dotfiles: `nix shell nixpkgs#git --command git clone https://github.com/benfiola/dotfiles ...`
8. From dotfiles directory, switch to the flake-defined config: `sudo nixos-rebuild switch --flake '.#[hostname]'`
9. Restart the distribution so the configured user (`wsl.defaultUser`) takes effect: `wsl -t [name]`, then `wsl -d [name]`.
10. Relocate dotfiles into the new user's home directory: `sudo mv [path] /home/[user]/source/github.com/benfiola/dotfiles && sudo chown -R [user]:users /home/[user]/source/github.com/benfiola/dotfiles`

Subsequent rebuilds use: `sudo nixos-rebuild switch --flake [path]#[hostname]`

---

## Hardware Configuration (NixOS)

Each NixOS host requires a `hardware.nix` file (e.g., `hosts/[hostname]/hardware.nix`).

### Generating hardware-configuration.nix

```bash
sudo nixos-generate-config --root /mnt
```

This generates two files: `hardware-configuration.nix` and `configuration.nix`. Copy `hardware.nix` to your flake:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/[hostname]/hardware.nix
```

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
