# sla_physics

The engine's physics seat, embedded in slaengine (owner ruling
2026-11-01: embedded for now, split out when mature — same tier as
`sla_ecs` / `sla_3d`).

- **Charter**: [CHARTER.md](CHARTER.md) — ownership, native-SLA clean-room
  route (extern binding of a reference engine rejected as the end form),
  the solver layer + self-developed analytic preview layer (swept
  time-of-impact, event-driven advance, will-events, multi-future
  rollouts, external-force scripts), the `step(world, dt, inputs)`
  contract, the four reference prerequisites, and the reference seats
  (Rapier primary / Jolt solver blueprint / Box2D v3 C-seat form /
  PhysX GPU-pipeline only / Bullet Blender-semantics cross-check).
- **Reference survey (light)**: [docs/REFERENCE_SURVEY.md](docs/REFERENCE_SURVEY.md)
  — per-engine absorption tables mapped onto this seat's contract.
- **Skeleton**: [src/physics.sla](src/physics.sla) — SLA type/signature
  skeleton (World/Body/Collider handles, step contract, Script/Branch
  data forms, WillEvent/OnEvent, swept-query signatures). Types and
  signatures only; no solver implementation yet.

Status: foundation batch 2026-11-01. Implementation awaits the physics
seat's formal scheduling. Workspace membership registration in
`workspace.toml` is a pending main-session decision (this batch is
pure-additive by constraint; no existing file was modified).
