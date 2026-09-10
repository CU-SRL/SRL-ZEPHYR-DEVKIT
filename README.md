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

- **One image** (`srl-zephyr-devkit`) holds the Zephyr SDK, `west`, apt build
  deps, and a Python venv. No repo is baked in.
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

1. Put `srl` on your PATH (pick one):
   ```bash
   echo 'export PATH="$HOME/SRL/SRL-ZEPHYR-DEVKIT/bin:$PATH"' >> ~/.zshrc
   exec zsh
   ```
2. Build the image (first run auto-builds; downloads the SDK, be patient):
   ```bash
   srl --build list
   ```

## Registering a repo

Copy `examples/srl.yml` to the repo root and edit it. Minimum:

```yaml
name: MY-REPO
app: app                       # dir passed to `west build`
default_board: nucleo_h723zg
```

See `examples/srl.yml` for board aliases, per-board overlays, debug configs,
and flash runners. `SRL-PHOENIX/srl.yml` is a real working example.

## Commands

```
srl list                                   list discovered repos
srl build  <repo>[/<board>] [opts] [-- …]  build (default: pristine)
srl run    <repo> [args…]                  run the native_sim executable
srl flash  <repo>[/<board>] [-r RUNNER]    flash a built image
srl menuconfig <repo>[/<board>]            open Kconfig menuconfig
srl clean  <repo>[/<board> | --all]        remove build dir(s)
srl update <repo>                          west update in that repo
srl refresh                                rescan the registry
srl shell                                  interactive shell, all repos mounted
```

Build options: `-b/--board`, `-d/--debug`, `-p/--pristine always|auto|never`,
`--no-pristine` (fast incremental), `-t/--target`, `-- <extra cmake args>`.
`<board>` may be a repo alias (`pcb`, `sim`, …) or a full Zephyr board name.

`srl build` auto-runs `west update` the first time a repo's `zephyr/` is empty.

## Config

- `SRL_WORKSPACES` — colon-separated roots to scan for repos. Default: the
  directory that contains this devkit checkout.

## Notes / limits

- The image ships **one** Zephyr SDK (`0.17.0`) and one set of Zephyr Python
  build deps (built for `v4.0.0`). Repos on a compatible Zephyr (v3.7+/v4.x)
  share it fine; a repo pinning something incompatible gets a warning from
  `srl` and may need a separately tagged image. Each repo declares its version
  via `zephyr:` in `srl.yml`.
- `srl` does not `west init` a workspace — a repo must already be a west
  workspace (have `.west/`). It will run the first `west update` for you.
