# slaengine

The SA/SLA engine monorepo: one workspace, crate-per-domain, an umbrella
crate on top. Home of the engine built from SLASL (shader toolchain),
SAX3D (asset format), sla_ecs (ECS, to be embedded), the 3D-engines port,
and the render backends (WebGL first, GPU second).

Remote: `https://github.com/layola13/slaengine`

## Layout

```
workspace.toml          workspace manifest — membership source of truth
crate.toml              umbrella package manifest (root crate)
src/slaengine.sla       umbrella entry: App-layer host (skeleton)
crates/
  slasl/                shader compiler (SLA tool)            [active]
  sax3d/                3D asset format + toolchain (Zig)     [active]
  sla_asset/            asset bridge seat (Jev F5)            [reserved]
  sla_ecs/              ECS embed seat                        [reserved]
  sla_3d/               sa_plugin_3dengines port seat         [reserved]
  sla_webgl/            render backend seat, priority 1       [reserved]
  sla_gpu/              render backend seat, priority 2       [reserved]
examples/smoke/         umbrella composition smoke
```

## Correspondence with Bevy

This workspace deliberately mirrors Bevy's repository organisation,
adapted to the SA/SLA ecosystem:

| Bevy | slaengine |
|---|---|
| Root `Cargo.toml` `[workspace]` member table | `workspace.toml` `[workspace]` `members` |
| Root package `bevy` (`src/lib.rs`, re-export facade) | Root crate `slaengine` (`src/slaengine.sla`, App-layer host) |
| `crates/bevy_*`, one crate per domain | `crates/<name>`, one crate per domain |
| Per-crate `Cargo.toml` | Per-crate `crate.toml` |
| `[workspace.package]` + `version.workspace = true` inheritance | Same: members write `version.workspace = true` and inherit `[workspace.package]` |
| `[workspace.dependencies]` shared dependency versions | `[workspace.dependencies]` shared external faces (today: `sa_std`) |
| `rust-version` toolchain pin | `[workspace.toolchain]` — pinned sci / sla / zig heads the workspace is verified against |
| App / Plugin / Schedule / System organisation | The umbrella entry's shape: `App` builder, Plugin registration, Schedule, System — see `src/slaengine.sla` |

Where the ecosystem differs from Bevy, the difference is explicit:

- **Members are heterogeneous.** Bevy's crates are all Rust libraries in
  one build system. Ours span the SA stack: SLA tools/libraries (built
  with the SLA toolchain, `sa build-exe`), Zig packages (`zig build`),
  and format specifications. There is no single cargo-like driver yet;
  each crate declares its own build/test entry in its `crate.toml`, and
  the umbrella smoke composes the active crates' public faces.
- **The umbrella re-export is App-shaped, not a flat facade.** Bevy's
  root crate re-exports crate APIs. Here the two active crates' public
  faces are a compiler CLI + shader files (slasl) and a format +
  toolchain (sax3d), so the umbrella's shared surface is the App layer:
  member crates register as Plugins into `App` (see
  `src/slaengine.sla`), and API-level re-export grows as library-form
  crates (sla_ecs, render backends) land.
- **sa_std is below the workspace, never inside it.** Platform capability
  lives in sa_std (sci); engine logic lives in member crates only.

## Organisation: App / System

The engine's runtime organisation follows Bevy's App/System model:

- **App** — the builder value hosted by the umbrella crate
  (`src/slaengine.sla`): owns registration and the run entry.
- **Plugin** — how a member crate joins an App (the two active crates
  register as founding Plugins today).
- **Schedule / System** — the execution organisation the ECS embed
  (crates/sla_ecs) and the render backends plug into when they land.
  No Schedules exist yet; the registration points are already in place.

## Build & test (on a Colab rig, toolchain per workspace.toml)

```sh
# sax3d crate (Zig)
cd crates/sax3d && zig build && bash tests/run_tests.sh && bash tests/run_convert.sh

# slasl crate (SLA tool; harness takes a build dir containing the crate)
bash crates/slasl/run_tests.sh <dir-with-slasl-crate>

# umbrella smoke (both active crates + umbrella entry, one flow)
bash examples/smoke/run_smoke.sh
```

## Status

Foundation stage: workspace skeleton + the two active crates are in
place and verified on the pinned rig (see FOUNDATION_REPORT.md). The
reserved crates are seats only — sla_ecs embed and the 3D-engines port
follow the survey line's plan; render backends follow in priority order
(WebGL, then GPU).
