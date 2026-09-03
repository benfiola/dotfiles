# Dotfiles

NixOS flake configuration for system management.

## Debugging & Diagnostics

**Validate flake syntax** — check for parse errors and missing dependencies.
```bash
nix flake check
```

**Show flake outputs** — list all outputs the flake provides (nixosConfigurations, devShells, etc).
```bash
nix flake show
```

**Display flake metadata** — see inputs, their resolved refs, and flake path.
```bash
nix flake metadata
```

**Update all inputs** — pull latest versions of all dependencies.
```bash
nix flake update
```

**Update specific input** — refresh a single input (e.g., nixpkgs).
```bash
nix flake update nixpkgs
```

**Show input details** — inspect what a specific input resolved to.
```bash
nix flake metadata --json | jq '.locks.nodes.nixpkgs'
```

**Dry-run a build** — evaluate the flake without building, catch evaluation errors.
```bash
nix build --dry-run '.#nixosConfigurations.your-host.config.system.build.toplevel'
```

**Build a specific output** — build a NixOS configuration.
```bash
nix build '.#nixosConfigurations.your-host.config.system.build.toplevel'
```

**Evaluate flake with verbose output** — see detailed evaluation process.
```bash
nix build --verbose --print-build-logs '.#nixosConfigurations.your-host.config.system.build.toplevel'
```

**Reload flake in REPL** — debug interactively.
```bash
nix repl
> :lf .
> nixosConfigurations
```

**Check for infinite recursion** — run with stack trace on evaluation errors.
```bash
NIX_SHOW_STATS=1 nix flake check
```

**Show installed package versions** — verify what's in your environment.
```bash
nix flake show --json | jq .
```
