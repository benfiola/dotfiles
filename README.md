# Dotfiles

Flake configuration for system management with support for NixOS (nixosSystem), macOS (nix-darwin), WSL (nix-wsl), and home-manager.

---

## Hardware Configuration (NixOS)

Each NixOS host requires a `hardware.nix` file (e.g., `hosts/bfiola-desktop-linux/hardware.nix`) that describes filesystems, bootloader, and hardware-specific settings.

### Generating hardware-configuration.nix

```bash
sudo nixos-generate-config --root /mnt
```

This generates two files: `hardware-configuration.nix` and `configuration.nix`. Copy `hardware.nix` to your flake:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix hosts/your-hostname/hardware.nix
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
