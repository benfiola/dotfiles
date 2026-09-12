# TODO

Porting the remaining `dotfiles-old` Ansible roles into flake modules. Pattern:
`modules/<name>/default.nix` returning `{ home, nixos, darwin }`, toggled from
`config.nix`.

## wireguard — own module, not `modules/apps`

- Both platforms are aligned on plain wg-quick `.conf` files now — no
  NetworkManager, no `ensureProfiles`, no per-field Nix templating on either
  side. `wireguard.tunnels` on a host's `config.nix` is a list of tunnel
  *names* (e.g. `[ "home" ]`), each with a colocated
  `modules/wireguard/<name>.conf.age` — the entire wg-quick config encrypted
  as one file, not just the private key. Nix's job per platform is just
  "decrypt this file to the right path with the right ownership":
  - darwin: `age.secrets.<name>.path` → `~/.wireguard/<name>.conf`, owned by
    the host user. `homebrew.masApps.WireGuard` (id `1451685025`) is still
    the actual on/off control — its menu bar toggle is the ad-hoc UX wanted,
    and WireGuard.app already expects exactly this wg-quick `.conf` format
    for its manual "Import tunnel(s) from file..." (no watched folder, no
    live reload, so this is still a one-time-or-per-rotation manual import).
  - nixos: `age.secrets.<name>.path` → `/etc/wireguard/<name>.conf`
    (`wg-quick`'s own bare-name lookup convention), mode `0400`.
    `pkgs.wireguard-tools` is installed, but nothing runs `wg-quick up` yet —
    the original plan (NetworkManager + `plasma-nm`'s tray applet for an
    ad-hoc GUI toggle) doesn't apply once NM is out of the picture, and no
    replacement toggle mechanism has been chosen (a KRunner/shortcut running
    `wg-quick up/down` with a scoped sudoers rule, a systemd service started
    via a desktop launcher, or just plain CLI — undecided, deliberately
    deferred). `networking.networkmanager.enable` still lives in
    `modules/kde` for unrelated reasons (general desktop networking, Arch
    parity) — no longer anything to do with wireguard.
- Secrets: `agenix`'s nixos/darwin modules (`inputs.agenix.{nixos,darwin}
  Modules.default` in `lib.nix`) provide the actual runtime mechanism —
  `age.secrets.<name>.file`/`.path`, decrypted at activation using
  `age.identityPaths` (hardcoded in `lib.nix`, alongside the shared operator
  pubkey, as `ageIdentityPath`/`ageRecipient` — every host shares one
  operator key rather than a distinct per-host identity, and both values
  live in exactly one place, referenced by `agenixIdentityModule` and the
  devShell's `age-edit` script). The `agenix` *CLI* and its `secrets.nix`
  convention were dropped after standing it up once and finding it just
  duplicated what `age.secrets.<name>.file = ./<name>.conf.age;` already
  declares — recipients only matter at encrypt time, decrypt-side options
  don't read `secrets.nix` at all. `age-edit <file>` (in the `nix develop`
  devShell) does decrypt-into-`vim`-reencrypt against the same hardcoded
  identity/recipient, with a `trap`-guaranteed temp-file cleanup — no
  separate rules file, no per-secret ceremony.
- The private key has to be decryptable at activation, so the identity
  (`/etc/age/host.key`) has to exist on a host *before* Nix does anything —
  an unavoidable one-time bootstrap step, same as `passwd`/`useradd` in
  `archlinux-instructions.sh`. Resolved as: one shared operator age key
  (not per-host), generated once, carried on a USB stick (or similar
  physical medium — no network/CLI dependency needed on a bare install
  environment), copied to `/etc/age/host.key` during every host's install.
- Still needed before this actually works on a host:
  1. Decide on a nixos toggle mechanism (see above).
  2. Set `wireguard.tunnels = [ "home" ];` (or whatever it ends up being
     named) on `bfiola-desktop-linux`'s `config.nix`.
  3. `age-edit modules/wireguard/home.conf.age` (from `nix develop`) with
     the real wg-quick config content.
  4. Copy the operator's `/etc/age/host.key` onto the host from the USB
     during install.

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
