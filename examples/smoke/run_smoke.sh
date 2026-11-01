#!/bin/bash
# slaengine umbrella smoke — one minimal flow that references BOTH active
# crates' public faces plus the umbrella entry, and runs through.
#
#   1. umbrella entry (src/slaengine.sla, App skeleton) builds and runs;
#   2. slasl public face: the crate's compiler builds, generates the
#      bundle product set from the crate's canonical shaders, and every
#      product byte-matches the crate's goldens;
#   3. sax3d public face: the crate builds (zig) and its checker accepts
#      the crate's cube example against its shader interface.
#
# Run ON a Colab rig (rig env sourced) FROM the workspace root:
#   bash examples/smoke/run_smoke.sh
set -u
cd "$(dirname "$0")/../.."
ROOT=$PWD
W=$ROOT/work/smoke
rm -rf "$W" "$ROOT/.sla-cache" "$ROOT/crates/slasl/.sla-cache"
mkdir -p "$W"
fails=0
pass() { echo "SMOKE PASS $1"; }
bad() { echo "SMOKE FAIL $1"; fails=$((fails + 1)); }

# 1. umbrella entry
if sa build-exe src/slaengine.sla -o "$W/slaengine" >"$W/umbrella_build.log" 2>&1 \
   && "$W/slaengine" >"$W/umbrella_run.log" 2>&1 \
   && grep -q "slaengine 0.1.0" "$W/umbrella_run.log" \
   && grep -q "plugins registered: 2" "$W/umbrella_run.log"; then
  pass umbrella-entry
else
  bad umbrella-entry
fi

# 2. slasl public face (compiler CLI + generated shader files vs goldens)
if sa build-exe crates/slasl/src/slasl.sla -o "$W/slasl" >"$W/slasl_build.log" 2>&1 \
   && "$W/slasl" "$W/slasl_out" crates/slasl/shaders/base.slasl crates/slasl/shaders/tint.slasl >"$W/slasl_run.log" 2>&1; then
  s2ok=1
  for f in crates/slasl/golden/*; do
    n=$(basename "$f")
    cmp -s "$f" "$W/slasl_out/$n" || { s2ok=0; echo "SMOKE DIFF slasl/$n"; }
  done
  [ $s2ok -eq 1 ] && pass slasl-generate || bad slasl-generate
else
  bad slasl-generate
fi

# 3. sax3d public face (toolchain + format checker on the crate example)
if (cd crates/sax3d && zig build --prefix "$W/sax3d-out") >"$W/sax3d_build.log" 2>&1 \
   && "$W/sax3d-out/bin/sax3dc" check crates/sax3d/examples/cube.sax3d \
        --iface PbrStd=crates/sax3d/examples/pbr_std.iface.txt >"$W/sax3d_check.log" 2>&1; then
  pass sax3d-check
else
  bad sax3d-check
fi

echo "SMOKE RESULT: fails=$fails"
[ $fails -eq 0 ]
