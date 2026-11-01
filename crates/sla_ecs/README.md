# crates/sla_ecs — the engine's ECS core (Bevy `bevy_ecs` counterpart)

The sla_ecs codebase, embedded as a first-class workspace crate: embedded
source, never an external dependency. Per the owner ruling (2026-11-01),
sla_ecs is no longer maintained as a standalone repository — slaengine is
its only home, and this crate is the single source of truth from the
takeover commit on. The upstream repository (`layola13/sla_ecs`) is frozen
at the migration baseline.

## Provenance

- Source: `layola13/sla_ecs` @ `1be020b` ("Fix ECS combinators to share
  world safely"), imported by the slaengine P0 batch (2026-11-01) under
  the survey plan's directory mapping (PLAN §2.3). Working copy and
  staging commits live in the P0 batch tree; acceptance = pre/post
  migration per-file test failure name sets equal (see `P0_REPORT.md` of
  that batch and the plan §2.3/§5).
- Import fidelity: `lib/` files byte-identical except the seven files
  whose `"lib/…"` imports were normalised to bare names (the plan's
  single normalisation point); `tests/` and `examples/` files differ
  only on `@import` lines (`lib/…` / `../lib/…` → `../src/…`). Diffs were
  audited line-wise at import time.
- Not imported (per plan): `lib/world_table_erased.sa` (build artifact),
  `src/main.sla` and `workspace_demo/` (`return 0` stubs — the umbrella
  smoke replaces them), `fix_while_semicolon.py` (one-off historical
  fix script).
- Pre-existing external reference, unresolved in both the source tree
  and this crate: `examples/state_scoped.sla` imports
  `../../sla_state/src/lib.sla` (a sibling repository that is not part
  of this takeover).

## Layout

| Directory | Content |
|---|---|
| `src/` | The library, flat: 521 `.sla` modules (272 base + 249 `*_deep` variants) plus `component_metadata.sai` / `.sal`. Bare-name imports throughout. |
| `tests/` | 426 per-file test files (mostly `*_isolated`). |
| `examples/` | 90 example files. |
| `docs/` | The source repository's documentation archive, including the original README with the Bevy parity tables and the philosophy-difference table (`docs/README.md`). |

Logical groups inside the flat `src/` (plan §2.2; physical split into
`crates/sla_tasks` / `crates/sla_reflect` is a P3 decision, by consumer):
**core** (entity/storage/archetype/world backends/query/commands/
schedule/system_param/messages/observer/relationship/resource/…),
**tasks** (`task_*`, `thread_executor*`, `parallel_runner`,
`parallel_scope`, `parallel_iterator`, `parallel_slice`, `parallel`),
**reflect** (`app_type_registry`, `reflect*`, `ecs_metadata`,
`metadata_identity`, `caller_location`, `component_metadata.*`).

## Public surface

The crate's committed external entry is the unified facade
**`src/ecs_world.sla`** (`ecs_world_*`), which covers the Bevy
`world::World` public API set. The multiple internal world backends
(fixed / registry / dynamic / table-erased / observer / relationship)
are implementation layers behind it. Source-repo assessment (2026-07-06
audit, in `docs/README.md`): API surface parity ~94–96%, behaviour
parity ~88–92% against Bevy.

## Test caliber

No unified runner exists upstream; the project's own caliber is
per-file: `SA_PLUGIN_DEV=1 sa sla test <file>` over every `.sla` in
`src/`, `tests/` and `examples/`, with two documented exceptions run
with `--test-backend sa` (`src/parallel_iterator.sla`,
`src/task_pool_builder.sla` — whole-file SAB issues on record in the
SLA plugin's docs, plan §2.4). `tests/run_tests.sh` in this crate
executes exactly that caliber and reports the failing-name set; it also
accepts the original tree layout for takeover comparisons.

## Known gaps (plan §2.4, unchanged by the takeover)

- Full TaskPool/Scope worker scheduling: P3, to ride the SA goroutine
  runtime — no second scheduler grows inside the engine.
- bevy_reflect-grade reflection (`TypeId` / `dyn Any`): a language-layer
  gap, not engine work; the descriptor registries in the reflect group
  are the long-term substitute form.
- Individual SAB-backend whole-file issues ride the compiler DEF queue;
  the takeover acceptance records them by name, it does not paper over
  them.
