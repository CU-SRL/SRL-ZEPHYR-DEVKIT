# SRL Zephyr devkit

One shared Docker build environment for **all** SRL Zephyr repos, plus a single
`srl` command that builds/flashes/runs any of them by name. Install Zephyr once
(in the image), never on your host.

```
srl build SRL-PHOENIX/pcb      # build phoenix_pcb in the SRL-PHOENIX repo
srl run   SRL-PHOENIX          # run its native_sim executable
srl list                       # show every discovered repo
srl shell                      # drop into a shell with all repos mounted
```

## How it works

- **One image** holds the Zephyr SDK, `west`, apt build deps, and a Python
  venv. No repo is baked in. It's **prebuilt by CI and pulled from GHCR**
  (`ghcr.io/cu-srl/srl-zephyr-devkit`), so the first run just downloads it —
  no local build, no SDK download on your machine.
- **Repos are discovered, not configured.** Any directory that sits **next to**
  this devkit checkout and contains an `srl.yml` is auto-registered. Add a new
  repo → drop in an `srl.yml` → it shows up the next time you run `srl`. No
  editing of the devkit needed. (Discovery is one level deep, by location, not
  by the parent folder's name.)
- Each repo is **bind-mounted** at `/workspaces/<dir-name>`, so host edits are
  live and build artifacts land back in the repo. Each repo stays its own
  independent west workspace (own `.west/`, `zephyr/`, `build/`).

```
<parent dir>/
├── SRL-ZEPHYR-DEVKIT/     <- this repo (the toolchain + srl tool)
├── SRL-PHOENIX/           <- has srl.yml  -> mounted at /workspaces/SRL-PHOENIX
└── SOME-OTHER-REPO/       <- has srl.yml  -> mounted at /workspaces/SOME-OTHER-REPO
```

## Setup (once)

1. Put `srl` on your PATH. Pick the block for your shell/OS (adjust the path if
   your checkout isn't at `$HOME/SRL/SRL-ZEPHYR-DEVKIT`):

   **macOS (zsh, the default):**
   ```bash
   echo 'export PATH="$HOME/SRL/SRL-ZEPHYR-DEVKIT/bin:$PATH"' >> ~/.zshrc
   exec zsh
   ```

   **Linux (bash):**
   ```bash
   echo 'export PATH="$HOME/SRL/SRL-ZEPHYR-DEVKIT/bin:$PATH"' >> ~/.bashrc
   exec bash
   ```

   **Windows:** `srl` is a bash script that drives Docker, so run it under
   [WSL2](https://learn.microsoft.com/windows/wsl/install) with Docker Desktop's
   WSL integration enabled. Inside your WSL distro it's the Linux setup above —
   clone the repo into the Linux filesystem (e.g. `~/SRL/...`, not `/mnt/c/...`,
   for bind-mount performance) and append the `export PATH` line to `~/.bashrc`.
   Git Bash also works if you prefer it (same line in `~/.bashrc`), but WSL2 is
   the smoother path for the Docker bind mounts.
2. Run any command — the first run **pulls** the prebuilt image from GHCR
   (`ghcr.io/cu-srl/srl-zephyr-devkit`), so there's nothing to build and no
   Zephyr SDK download on your machine:
   ```bash
   srl list
   ```
   - `srl --pull …` refreshes to the latest published image.
   - `srl --build …` builds the image locally from `docker/Dockerfile.dev`
     instead (for offline use, or when changing the image itself).

## Registering a repo

Copy `examples/srl.yml` to the repo root and edit it. Minimum:

```yaml
name: MY-REPO
app: app                       # dir passed to `west build`
default_board: nucleo_h723zg
```

See `examples/srl.yml` for board aliases, per-board overlays, debug configs,
flash runners, and the optional `workspace:` / `manifest:` keys. `zephyr:` is
informational only (each repo builds its own pulled `zephyr/`), so it need not
match the image. `SRL-PHOENIX/srl.yml` is a real working example.

A brand-new repo with only an `srl.yml` (no `.west/` yet) is bootstrapped with
`srl init <repo>` — it runs `west init` then `west update` to pull Zephyr and
all modules. `srl build` / `srl update` also auto-init when `.west/` is missing.
`srl init` gets the manifest from the `manifest:` key in `srl.yml` (a URL to
clone, or a local manifest subdir); with none set it auto-detects a single
manifest-bearing subdir. The manifest must live in a **subdirectory** of the
workspace — `west init` creates `.west/` in the manifest dir's parent, so a
root-level `west.yml` would place `.west/` outside the repo (srl stops you with
guidance if so).

## Commands

```
srl list                                   list discovered repos
srl build  <repo>[/<board>] [opts] [-- …]  build (default: pristine)
srl run    <repo> [args…]                  run the native_sim executable
srl flash  <repo>[/<board>] [-r RUNNER]    flash a built image
srl menuconfig <repo>[/<board>]            open Kconfig menuconfig
srl clean  <repo>[/<board> | --all]        remove build dir(s)
srl init   <repo>                          west init + update a not-yet-set-up repo
srl update <repo>                          west update in that repo
srl refresh                                rescan the registry
srl shell                                  interactive shell, all repos mounted
```

Build options: `-b/--board`, `-d/--debug`, `-p/--pristine always|auto|never`,
`--no-pristine` (fast incremental), `-t/--target`, `-- <extra cmake args>`.
`<board>` may be a repo alias (`pcb`, `sim`, …) or a full Zephyr board name.

`srl build` auto-runs `west init`/`west update` the first time a repo isn't a
workspace yet or its `zephyr/` is empty.

## Config

- `SRL_WORKSPACES` — colon-separated roots to scan for repos. Default: the
  directory that contains this devkit checkout.

## Notes / limits

- The image ships **one** Zephyr SDK (`0.17.0`) and one set of Zephyr Python
  build deps (built for `v4.0.0`), but the **Zephyr source is per-repo** — each
  repo's `west update` pulls its own `zephyr/` at whatever its `west.yml` pins,
  and that tree is what's built. The image's SDK + base deps cover Zephyr
  v3.7+/v4.x, so repos across that range share it fine; `zephyr:` in `srl.yml`
  is just an informational note (a differing value prints a one-line note, not
  a warning). A repo needing a genuinely incompatible Python dep set would need
  a separately tagged image.
- `srl init <repo>` bootstraps a repo that isn't a west workspace yet (runs
  `west init` then `west update`); `srl build`/`srl update` auto-init too. The
  manifest must sit in a subdirectory of the workspace — see *Registering a
  repo*.
