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

### nix flake show

List all outputs the flake provides (configurations, devShells, packages, etc).

**Arguments:**

- (none) — shows all outputs
- `--json` — machine-readable output

**Example:**

```bash
nix flake show
nix flake show --json | jq .
```

**Why:** See what outputs are available and verify your flake structure is correct.

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
nix flake update nixpkgs home-manager
```

**Why:** Pull latest packages, fixes, and security patches; or refresh a single input without full rebuild.

---

### nix build

Evaluate and build a flake output.

**Arguments:**

- `.#<output-path>` — output to build (e.g., `.#darwinConfigurations.my-mac.system` or `.#homeConfigurations.user.activationPackage`)
- `--dry-run` — evaluate without actually building
- `--verbose` — show detailed build logs
- `--print-build-logs` — stream build output

**Example:**

```bash
nix build '.#<your-config>'                                    # Build a configuration
nix build --dry-run '.#<your-config>'                          # Evaluate only, catch errors
nix build --verbose --print-build-logs '.#<your-config>'       # See detailed output
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

---

## Home Manager

### Build home-manager activation package

Evaluate and build the home-manager configuration.

**Arguments:**

- `.#homeConfigurations.<user>.activationPackage` — the activation package to build
- `--dry-run` — evaluate without building

**Example:**

```bash
nix build '.#homeConfigurations.<user>.activationPackage'
nix build --dry-run '.#homeConfigurations.<user>.activationPackage'
```

**Why:** Test that your home-manager config compiles; identify evaluation errors before activation.

---

### Inspect home-manager config

View what packages and settings would be applied.

**Example:**

```bash
nix repl
> :lf .
> homeConfigurations.<user>.config.home.packages
> homeConfigurations.<user>.config.programs.git.enable
```

**Why:** Debug configuration values and see what would be activated without running it.
