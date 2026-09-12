# TODO

Porting the remaining `dotfiles-old` Ansible roles into flake modules. Pattern:
`modules/<name>/default.nix` returning `{ home, nixos, darwin }`, toggled from
`config.nix`.

## wireguard — own module, not `modules/apps`

- darwin: mas app (id `1451685025`) — the GUI client only, same as before.
- NixOS: skips the `wireguird` GTK client entirely (unpackaged, Go+GTK3 with
  a `fileb0x`-generated asset step and no real maintenance signal — not
  worth vendoring a `buildGoModule` derivation for). Instead the tunnel is a
  declarative NetworkManager connection profile
  (`networking.networkmanager.ensureProfiles`), which gets `plasma-nm`'s tray
  applet for free on KDE hosts (`plasma6.nix` adds it automatically whenever
  `networking.networkmanager.enable` is on) — no custom package needed.
  `networking.networkmanager.enable` itself lives in `modules/kde` right next
  to `services.pipewire`, not its own module — same "bundle infra the
  desktop session wants" precedent, and there's no nixos host in this fleet
  that wants NM without KDE (or KDE without NM) to justify splitting it out.
  `modules/wireguard` doesn't check for this — enabling wireguard on a nixos
  host without kde just silently produces a NetworkManager connection
  profile that never applies (no NM running to apply it), no error. Same
  tradeoff as everywhere else post-unwind (see "fail-fast on unsupported
  `*.enable`" below); worth remembering if this fleet ever grows a
  non-KDE nixos host that wants the tunnel.
- `modules/wireguard` is done (mechanism only). `agenix` is wired in as a
  flake input + nixos module, with a
  `nix develop` devShell exposing the `agenix` CLI. Secrets use a single
  shared operator age key (not per-host, not ssh-host-key-based) delivered
  onto each machine out-of-band (USB) as `/etc/age/host.key` during
  install — one identity file has to exist before a host can decrypt
  anything at all, and a shared operator key means that file is identical
  across hosts (provisioned once, copied everywhere) instead of needing a
  distinct one minted and distributed per host.
- Still needed before this actually works on a host:
  1. `age-keygen` the real operator key once, replace the placeholder
     pubkey in `secrets/secrets.nix`.
  2. Set `wireguard.tunnel = { name; address; peerPublicKey; endpoint;
     allowedIPs; }` on `bfiola-desktop-linux`'s `config.nix` (the actual
     tunnel/peer values aren't decided yet).
  3. `agenix -e secrets/<tunnel.name>.env.age` (from `nix develop`) with a
     `WG_PRIVATE_KEY=...` line.
  4. Copy `/etc/age/host.key` onto the host from the USB during install.

## Supporting work

- ~~**`firefox` / `chromium`**~~ — replaced, not ported. `dotfiles-old`'s
  `firefox.cfg`/`autoconfig.js` was ~100 privacy-hardening prefs plus a
  `policies.json` force-installing uBlock Origin, Bitwarden, and the Nord
  theme. `modules/firefox` uses LibreWolf instead (`programs.firefox.package =
  pkgs.librewolf`, a real nixpkgs package on both nixos and darwin, no
  homebrew cask needed — same "this slot installs a specific app, not
  necessarily the eponymous one" precedent as the old chromium role installing
  actual Google Chrome) — its upstream `librewolf.cfg`/`policies.json` already
  bake in the same hardening (that's the point of the fork) and it ships
  uBlock Origin by default, so the module only force-installs Bitwarden and
  Nord theme via `policies.ExtensionSettings`. chromium dropped entirely,
  not just deferred.
- ~~**`macos`**~~ — done (`modules/macos`). `config.sh`'s `defaults write`
  calls ported to `system.defaults.{dock,finder,NSGlobalDomain}` where a
  native nix-darwin option exists (dock autohide, Finder desktop icons,
  keyboard/spelling behavior, …); the handful without one (Safari dev menu,
  `NSQuitAlwaysKeepsWindows`, Finder's `WarnOnEmptyTrash`) go through
  `system.defaults.CustomUserPreferences`. `macos.enable` defaults to `true`
  for darwin hosts in `config.nix`, `false` everywhere else — no assertion
  enforcing that (see "fail-fast on unsupported `*.enable`" below).
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
- **fail-fast on unsupported `*.enable`** — tried, then fully unwound; none
  of it exists anymore. Went through three stages: (1) hand-rolled
  `!(config.X.enable && config.platform != "y")` assertions in
  `kde`/`macos`/`docker` (wsl-specific) plus per-app package/cask-presence
  assertions in `modules/apps`; (2) generalized that into a
  `platforms = [...]` field any module could declare, consumed generically
  by `lib.nix` (plus a systemic check that `config.platform` itself is a
  recognized value), so any unsupported combination — including a
  not-yet-invented third platform — would fail loudly instead of silently
  no-op-ing; (3) removed all of it, including stage (1)'s original checks.
  The generic mechanism in particular added real complexity to `lib.nix`
  (tripped over a genuine Nix module-system footgun: a hand-written wrapper
  function's own argument pattern determines which specialArgs — `pkgs`
  included — the module system injects into whatever it wraps, so wrapping
  silently dropped `pkgs` from every `home` module) to guard against a
  platform that isn't on the roadmap. And even the narrower, pre-existing
  checks were validating things a single-user 3-host repo doesn't need
  validated for it — a misconfigured `*.enable` now just silently produces
  no effect, which is easy enough to notice and fix by hand.
  `config.nix` needs platform-correct enables up front; nothing in
  `modules/` double-checks that anymore. Where a host property really does
  need to flip other `.enable` flags (wsl disabling docker), that derivation
  lives in `config.nix` itself now — a `wslNixos` block merged in exactly
  like `graphicalNixos`/`darwin` already were, keyed off `host.wsl` the same
  way those are keyed off `profile`/`platform` — rather than each host
  repeating the override or a module reaching for `config.wsl` at the point
  of use.
- **`c` role** — dropped for now; revisit if a global C toolchain is wanted vs
  per-project `nix develop`.
- ~~**`vscode`**~~ — done (`modules/vscode`). Old role's `vscode-init` shell
  helper (scaffolded per-project `.vscode/settings.json`) dropped entirely,
  not ported — never used. Replaced with `programs.vscode`: `pkgs.vscode`
  (not vscodium — needed for the Dev Containers extension, which Microsoft
  restricts to official builds/marketplace), extensions declared via the
  `nix-vscode-extensions` flake input's marketplace mirror
  (`mutableExtensionsDir = false`, fully declarative), user settings ported
  from the real
  `settings.json`/`extensions.txt` with `settingsSync.ignoredExtensions`,
  the dead `go.*` setting (no Go extension installed), and the `[nix]`
  formatter setting (nix-ide is repo-local, not global — see
  `.vscode/settings.template.json`) dropped; `anthropic.claude-code` added
  to the extension list since settings already referenced it but it was
  missing from the source extension list. Gated the same as
  `firefox`/`ghostty` (`graphicalNixos` + `darwin`).
- ~~**`steam`**~~ — done (`modules/steam`). `wine` and `proton` existed only
  to run Windows games under Steam, so both folded into this one module
  instead of getting their own: `programs.steam.enable` (nixos, needs
  `nixpkgs.config.allowUnfreePackages = [ "steam" ]`) plus
  `wineWow64Packages.staging` (`wineWowPackages` is upstream-deprecated),
  `winetricks`, and `protonup-qt` as home packages. `proton` dropped from
  `modules/apps` since it's no longer standalone. `xbox` dropped entirely —
  no longer used, not worth a `hardware.xone` module for nobody.

## Intentionally not ported (Nix replaces the mechanism)

facts, utils, user, apt, brew, pacman, mas, flatpak (role), fat, open_vm_tools,
source (folded into `modules/zsh`).
