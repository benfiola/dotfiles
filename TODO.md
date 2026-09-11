# TODO

Porting the remaining `dotfiles-old` Ansible roles into flake modules. Pattern:
`modules/<name>/default.nix` returning `{ home, nixos, darwin }`, toggled from
`config.nix`.

## Port later — needs real translation work

### kde — `dotfiles-old/roles/kde`

- NixOS only, graphical hosts.
- `services.displayManager.sddm.enable`, `services.desktopManager.plasma6.enable`,
  pipewire (`services.pipewire.{enable,pulse.enable}`).
- The role's `config.sh` / `root_config.sh` KDE tweaks need translating — either
  `programs.plasma` (plasma-manager, add as a flake input) or a home-manager
  activation script.
- Gate on the `graphical` profile (see Supporting work).

### macos — `dotfiles-old/roles/macos`

- nix-darwin only.
- Role runs `config.sh`, a pile of `defaults write`. Map each to
  `system.defaults.*` (dock, finder, NSGlobalDomain, trackpad, …).

### firefox / chromium policies — `dotfiles-old/roles/{firefox,chromium}`

- Enterprise policy JSON installed to system paths.
- NixOS: `programs.firefox.policies = { ... }` (native); chromium via
  `environment.etc."chromium/policies/managed/policy.json"`.
- darwin: `.mobileconfig` / `defaults` — lower priority.
- Only worth it if managed browser policy is actually wanted.

### vscode — `dotfiles-old/roles/vscode`

- Current role is just a `vscode-init` shell helper that scaffolds
  `.vscode/settings.json` per project — not editor config.
- Decision: keep it as a zsh function, or replace with `programs.vscode`
  (real settings + extensions sync).

## GUI apps with a real NixOS knob

steam, wine, xbox — unlike the rest of the GUI apps (now `modules/apps`, see
`config.nix` for the per-app `enable` flags), these need more than "install
one package", so split each into its own module when a host needs it:

- steam → `programs.steam.enable`
- wine → `wineWowPackages.staging` + `winetricks`
- xbox → `hardware.xone` (nixos-hardware input)

### wireguard — own module, not `modules/apps`

- darwin: mas app (id `1451685025`) — the GUI client only, same as before.
- NixOS: no nixpkgs package for a GTK client (`wireguird` isn't packaged —
  checked 26.05 and unstable); would need a custom `buildGoModule`
  derivation for `UnnoTed/wireguird` if a GUI is wanted there.
- Either way this module needs to go beyond the client app: actual
  `wg-quick`/`networking.wireguard.interfaces` config, and private keys
  need a secrets story — pull in `agenix` (new flake input) rather than
  committing keys in plaintext.

## Supporting work

- ~~**`graphical` profile**~~ — done. `bfiola-desktop-linux` sets
  `profile = "graphical"`; the `os` block in `config.nix` enables
  `ghostty`/`fonts` only for graphical NixOS hosts (not `bfiola-desktop-wsl`).
  darwin ignores `profile` (always graphical). Wire `kde` the same way once
  it exists.
- **`c` role** — dropped for now; revisit if a global C toolchain is wanted vs
  per-project `nix develop`.

## Intentionally not ported (Nix replaces the mechanism)

facts, utils, user, apt, brew, pacman, mas, flatpak (role), fat, open_vm_tools,
source (folded into `modules/zsh`).
