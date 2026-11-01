# crates/sla_webgl — RESERVED (render backend, priority 1)

Placeholder only. This directory reserves the workspace seat for the
**WebGL render backend** — the engine's first rendering surface
(owner priority: WebGL first, then Web3D/GPU in `crates/sla_gpu`).

When chartered, the backend lands here and registers with the umbrella
App layer as a Plugin. Shaders for this backend are produced by
`crates/slasl`; assets by `crates/sax3d`.

No content lives here yet; do not add code to this directory outside the
render-backend charter.
