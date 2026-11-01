# sla_gpu — filled-stock provenance (fill batch B, 2026-11-01)

This seat was a placeholder. Fill batch B copied existing ecosystem stock
in **as-is** (byte-identical except where an import path is noted), per the
user's 2026-11-01 fill instruction and the survey plan's verdict for
`sa_plugin_3d_render_wgpu` (`~/workspace/slaengine-survey/PLAN.md` §4.3:
「改造后移植（第二期）」 — the retrofit itself is P2 work; this batch only
lands the stock). The plugin host shells (`src/plugin.zig`,
`src/module_config.zig`, `sap.json`, `build.zig` of both source plugins)
were **not** copied: plugin-era scaffolding retires per PLAN §4.2/§4.3.

## Core stock — sa_plugin_3dengines @ `06f4fae`

(remote main == box clone head == `06f4faee99d95b79b65b8d6f2cce885f5ecd8bb5`;
box-verified copy at `~/workspace/slaengine-survey/sa_plugin_3dengines/`)

| In-crate path | Source path | Form |
|---|---|---|
| `src/3d_render_wgpu.sai` | `sa_plugin_3d_render_wgpu/3d_render_wgpu.sai` | byte-identical (sha256 `7423a72b…`) — `sa3d_wgpu_*` host extern surface |
| `src/3d_render_wgpu.sal` | `sa_plugin_3d_render_wgpu/3d_render_wgpu.sal` | 1-line import normalisation: `../../sa_plugin_wgpu/wgpu.sal` → `wgpu/wgpu.sal` (the in-seat dependency copy below). **One import left byte-identical and dangling by design**: `../sa_plugin_3d_shader/3d_shader.sal` — PLAN rules `3d_shader` is NOT ported (slasl is the shader truth); the file uses its `SA3D_SHADER_ENTRY_*` layout constants. See the blocker registration in `FILL_REPORT.md`. |
| `tests/3d_render_wgpu_layout_test.sa` | `sa_plugin_3d_render_wgpu/tests/3d_render_wgpu_layout_test.sa` | import normalisation only: `../3d_render_wgpu.sal` → `../src/3d_render_wgpu.sal` (1 line) |

## Dependency stock — sa_plugin_wgpu @ `ed61845f`

(head `ed61845f56031c4da9a7dd1ecf1597e162c7c4e5`, refs/box/master of the
local backup mirror; box `/content/sa_all/sa_plugin_wgpu` head agrees.
This is the library half of the wgpu plugin — the constants/layout `.sal`
that `3d_render_wgpu.sal` imports. Copying the library is not a plugin
dependency: no host shell, `sap.json`, or plugin registration is copied.
Jev ruling F3 (0.97) still governs the end state — sla_gpu's own wasm
import surface replaces this provenance in P2.)

| In-crate path | Source path | Form |
|---|---|---|
| `src/wgpu/wgpu.sal` | `wgpu.sal` (plugin root) | byte-identical (sha256 `2e59db0a…`) — WGPU_* constants + `@sa_wgpu_*` SA functions; no imports of its own |
| `src/wgpu/wgpu.sai` | `wgpu.sai` (plugin root) | byte-identical (sha256 `9657240a…`) — `sa_wgpu_*` host extern declarations |
| `tests/wgpu_layout_test.sa` | `tests/wgpu_layout_test.sa` | import normalisation only: `../wgpu.sal` → `../src/wgpu/wgpu.sal` (1 line) |

Not copied from sa_plugin_wgpu: `src/plugin.zig`, `src/plugin_api.zig`,
`src/wgpu_airlock_gen.zig`, `demos/`, `tools/verify_*.mjs`, `build.zig`,
`sap.json`, `package.json` (plugin host + its own sidecar/demo/verify
scaffolding; the P2 own-surface batch decides sla_gpu's broker form).
