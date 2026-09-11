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

## GUI apps — one list, not a module each

alfred, bitwarden, contexts, discord, gimp, magnet, spotify, steam, tidal,
whatsapp, wireguard, lutris, wine, xbox, proton.

Each is "install one package" with a per-OS branch. Plan:

- one `modules/apps` (or the `graphical` profile) reading lists from `config.nix`:
  - `packages` — nixpkgs, Linux (`discord`, `gimp`, `spotify`, …)
  - `casks` — homebrew, darwin; contribute via each app's `darwin` output, same
    as `modules/ghostty` does `homebrew.casks = [ "ghostty" ]`
  - `mas` — `homebrew.masApps = { Magnet = 441258766; … }`
- Split out the ones with a real NixOS knob when a host needs them:
  - steam → `programs.steam.enable`
  - wine → `wineWowPackages.staging` + `winetricks`
  - xbox → `hardware.xone` (nixos-hardware input)

## Supporting work

- **`graphical` profile** — `config.nix` has a `profile` hook (`host.profile`),
  currently unused. Wire it so desktop-only modules (kde, ghostty, fonts, GUI
  apps) default `enable` from it instead of blanket `true`.
- **`config.nix` `os` block** — currently `{ } // (if … then { } else { })`
  placeholders. If populated, use `lib.optionalAttrs`, not `mkIf`.
- **`c` role** — dropped for now; revisit if a global C toolchain is wanted vs
  per-project `nix develop`.

## Intentionally not ported (Nix replaces the mechanism)

facts, utils, user, apt, brew, pacman, mas, flatpak (role), fat, open_vm_tools,
source (folded into `modules/zsh`).
