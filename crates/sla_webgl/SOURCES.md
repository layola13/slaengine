# sla_webgl — filled-stock provenance (fill batch B, 2026-11-01)

This seat was a placeholder. Fill batch B copied existing ecosystem stock
in **as-is** (byte-identical except where an import path is noted), per the
user's 2026-11-01 fill instruction and the survey plan's disposition for the
aggregate plugin (`~/workspace/slaengine-survey/PLAN.md` §4.3, aggregate
row, dispositions ② and ⑤). Nothing here is retrofitted yet: the stock
targets WebGPU; retargeting the import surface + broker to WebGL is the
P1 connect-through work, not this batch.

Source of record: `sa_plugin_3dengines` @ `06f4fae` (box-verified copy at
`~/workspace/slaengine-survey/sa_plugin_3dengines/`, remote main == box
clone head == `06f4faee99d95b79b65b8d6f2cce885f5ecd8bb5`).

| In-crate path | Source path (in sa_plugin_3dengines) | Form |
|---|---|---|
| `src/sa3d.sai` | `sa_plugin_3d/sa3d.sai` | byte-identical (sha256 `51ad4a50…`) — wasm import surface |
| `src/sa3d.sal` | `sa_plugin_3d/sa3d.sal` | byte-identical (sha256 `fd3ac2c8…`) — sidecar ABI + SA-owned cube shader/geometry constants |
| `src/sa3d_airlock_runtime.js` | `sa_plugin_3d/src/sa3d_airlock_runtime.js` | byte-identical (sha256 `ae42631a…`) — airlock JS broker |
| `src/sa3d_airlock_gen.zig` | `sa_plugin_3d/src/sa3d_airlock_gen.zig` | byte-identical (sha256 `bfdb8d41…`) — Zig auxiliary: embeds the broker JS (`@embedFile`, same-dir relation preserved) |
| `tests/sa3d_sidecar_layout_test.sa` | `sa_plugin_3d/tests/sa3d_sidecar_layout_test.sa` | import-path normalisation only: `../sa3d.sai` → `../src/sa3d.sai`, `../sa3d.sal` → `../src/sa3d.sal` (2 lines) |

Not copied from the aggregate plugin, per PLAN dispositions:
`3d.sal` + `tests/3d_aggregate_layout_test.sa` (module mask — replaced by
workspace.toml, disposition ①); `demos/*.sax` (historical reference, ③);
`demos/*_decl.sax3d` + `tools/lower_sa3d_scene.mjs` +
`tests/sa3d_scene_cubes_layout_test.sa` (retired Scene3D declarative
format — **not** the frozen SAX3D format despite the similar name, ④);
`tools/verify_*.mjs`, `src/plugin.zig`, `src/module_config.zig`,
`sap.json`, `build.zig` (plugin-era workflow/host scaffolding, retired).

Language-doctrine note: the `.sal`/`.sai`/`.js` stock is the seat's main
body; `sa3d_airlock_gen.zig` is registered as an auxiliary support file
behind the `.sai` surface, per the engine's SLA-first doctrine.
