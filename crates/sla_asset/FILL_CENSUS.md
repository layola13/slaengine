# sla_asset — fill census (fill batch B, 2026-11-01)

**Census outcome: no copyable stock exists for this seat. The placeholder
stands, deliberately.** This page is the one-page explanation required by
the fill batch; the full census table lives in the batch's
`FILL_REPORT.md` (workspace root of the fill work copy).

Why there is nothing to copy:

- Per the survey plan (§2.5, connect-through checklist C1–C8), this crate
  is **new-build work** (P1): a bridge that consumes the SAX3D §4.5 parse
  product and the slasl interface-table contract and generates ECS
  entities through the `ecs_world_*` facade. No such bridge code exists
  anywhere in the ecosystem yet — that is precisely the P1 work item.
- Adjacent stock was surveyed and each item has a disposition elsewhere:
  - `sa_plugin_3d_gltf`'s loader-settings surface — PLAN verdict: **not
    ported** (the sax3d converter is the glTF truth); its settings/flags
    may serve as design reference for this seat's load-options face, but
    PLAN forbids copying the code in.
  - SAX3D-side fixtures (e.g. interface-table samples under
    `crates/sax3d/examples/`) — already live inside `crates/sax3d`;
    duplicating them here would violate the fill rule against repeating
    the format crate's own content.
  - `sa_plugin_3d_scene`'s declarative lowering fixtures — assigned to
    `crates/sla_3d` / retired with the old Scene3D format (PLAN §4.3);
    scene *data* truth belongs to SAX3D, runtime scene ops to sla_3d.
  - The full plugin family on the box (`/content/sa_all`) and the local
    mirrors were checked: there is no asset/loader plugin in the
    ecosystem (family = 3dengines, wgpu, sax, sla, db, node, deno, bc2sa,
    http_*, mui, pkg, react, ts, tui, vite, vm).

So this seat's first real content is the P1 bridge implementation itself,
not a fill. No placeholder-filler files were invented to make the seat
look populated.
