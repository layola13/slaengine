# crates/sla_3d — 3D domain modules

One crate, domain subdirectories (Jev ruling F1) — the Bevy
`bevy_math` / `bevy_time` / `bevy_input` / `bevy_color` /
`bevy_transform` / … counterparts for slaengine, ported one-shot from
`sa_plugin_3dengines` @ `06f4fae` (frozen; this crate is their only
home now). Adjudication per module: the survey plan's ruling table
(PLAN §4.3); phasing per PLAN §5.

## Landed: batch A (P0)

| Domain | Bevy counterpart | Form | Contents |
|---|---|---|---|
| `src/math/` | bevy_math / glam | rework-port per plan (kernels per F2) | `3d_math.sal` (Vec2/3/4, Quat, Mat4, Ray3d, Aabb3d, BoundingSphere) + `native/math.zig` f32 kernel (60 exports, 6 unit tests) |
| `src/time/` | bevy_time | direct port | `3d_time.sal` (frame advance, Timer) + `native/time.zig` clock/timer state kernel (14 exports, 1 unit test). The kernel never reads a host clock — all inputs are explicit nanosecond values, so the plan's "rebind host clock to sa_std" note has no kernel-side object; host time injection is a future App/host-layer concern. |
| `src/input/` | bevy_input | direct port | `3d_input.sal` (ButtonInput state machine). No native kernel (host was boilerplate); event sources inject via the future WebGL host surface. |
| `src/color/` | bevy_color | direct port | `3d_color.sal` (RGBA packing, sRGB/linear). No native kernel. |
| `src/transform/` | bevy_transform | rework-port per plan (kernels per F2) | `3d_transform.sal` (Transform/GlobalTransform, SRT, propagation) + `native/transform.zig` kernel (29 exports, 3 unit tests) |

Each domain's SA layout test lives at `tests/<domain>/` and runs under
the source family's caliber (see `tests/run_tests.sh`): support libs
built by `build.zig`, then `sa test` per domain with
`SA_PLUGINS_PATH` pointing at that domain's lib (input/color run
without it). math's i32 fixed-point smoke path exists only inside its
test corpus, not as API (plan §4.3).

The kernels register with the host through `native/saasm_abi.zig`, a
crate-local ABI shim: the SA host loads a dev-mode `.so` only when it
exports the plugin descriptor symbols (sci `plugins.zig`
loadDescriptor/validateDescriptor check abi_version and
descriptor_size), and the layout tests resolve their extern selftest
entry points through that loading. The shim keeps only the
descriptor identity (abi_version, size, the domain's plugin name;
`handle_command` null, no skills) — the source framework's CLI
command handler and skill registry retire with the framework, as do
its 3 framework unit tests; the kernels' own unit tests all migrate.
Per the engine language doctrine the native kernels are an auxiliary
surface behind this ABI; the behaviour layer is the `.sal`.

## Pending, on record

- **Batch B (P1)**: geometry, camera, camera_controller, image,
  material, pbr, light, scene, animation, gizmos, particle — per the
  plan's ruling table (with their noted reworks).
- **transform propagation re-hang**: the plan's final form hangs
  propagation on sla_ecs Systems with hierarchy relations as the
  parent truth source (no module-private parent table). Batch A
  migrates the behaviour as-is; the re-hang is P1 wiring work
  (connect-through item C2) and is not silently dropped.
- **math/geometry Zig kernels**: geometry's kernel joins under the
  same F2 support-library form in batch B.
