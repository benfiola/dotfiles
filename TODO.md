# TODO

Porting the remaining `dotfiles-old` Ansible roles into flake modules. Pattern:
`modules/<name>/default.nix` returning `{ home, nixos, darwin }`, toggled from
`config.nix`.

## Port later — needs real translation work

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

- ~~**`macos`**~~ — done (`modules/macos`). `config.sh`'s `defaults write`
  calls ported to `system.defaults.{dock,finder,NSGlobalDomain}` where a
  native nix-darwin option exists (dock autohide, Finder desktop icons,
  keyboard/spelling behavior, …); the handful without one (Safari dev menu,
  `NSQuitAlwaysKeepsWindows`, Finder's `WarnOnEmptyTrash`) go through
  `system.defaults.CustomUserPreferences`. `macos.enable` defaults to `true`
  for darwin hosts in `config.nix`; asserts (in the `home` block, like
  `kde`/`docker`) if enabled elsewhere.
- ~~**`graphical` profile**~~ — done. `bfiola-desktop-linux` sets
  `profile = "graphical"`; the `os` block in `config.nix` enables
  `ghostty`/`fonts` for graphical hosts on every platform, plus
  `graphicalNixos`/`graphicalDarwin` splits for apps and `kde` that only
  exist on one platform (`bfiola-desktop-wsl` gets neither since it has no
  `profile`). darwin ignores `profile` (always graphical).
- ~~**`kde`**~~ — done (`modules/kde`). `services.displayManager.sddm` +
  `services.desktopManager.plasma6` on the NixOS side; the `config.sh` /
  `root_config.sh` tweaks ported to `programs.plasma` via plasma-manager
  (workspace theme, fonts, krunner, shortcuts, krunner plugin disables) on
  the home-manager side.
- **fail-fast on unsupported `*.enable`** — done. `modules/apps`, `docker`,
  and `kde` now assert instead of silently no-op-ing when a host enables
  something its platform can't provide (e.g. `magnet.enable` on NixOS,
  `docker.enable` on WSL, `kde.enable` on darwin), so `config.nix` needs
  platform-correct enables up front rather than relying on modules to
  quietly skip unsupported combinations.
- **`c` role** — dropped for now; revisit if a global C toolchain is wanted vs
  per-project `nix develop`.

## Intentionally not ported (Nix replaces the mechanism)

facts, utils, user, apt, brew, pacman, mas, flatpak (role), fat, open_vm_tools,
source (folded into `modules/zsh`).
