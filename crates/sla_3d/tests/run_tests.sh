#!/bin/bash
# sla_3d test caliber — mirrors the source family's per-module caliber
# (sa_plugin_3dengines build.zig): native support libraries are built
# with zig and their embedded unit tests run via `zig build test`;
# each domain's SA layout test then runs under `sa test` with
# SA_PLUGINS_PATH pointing at that domain's support library (the
# extern selftest entry points live in the kernels). input/color have
# no native kernel — their layout tests exercise the .sal only and run
# without SA_PLUGINS_PATH, as in the source family (their plugin hosts
# were framework boilerplate with no exports).
set -u
cd "$(dirname "$0")/.." || exit 2
ZIG=${ZIG:-zig}
SA=${SA:-sa}
echo "== zig build (native support libs) =="
"$ZIG" build || { echo "BUILD FAIL"; exit 1; }
echo "== zig build test (kernel unit tests) =="
"$ZIG" build test || { echo "ZIG TEST FAIL"; exit 1; }
fail=0
for d in math time input color transform; do
  t="tests/$d/3d_${d}_layout_test.sa"
  case $d in
    math|time|transform) export SA_PLUGINS_PATH="$PWD/zig-out/lib/lib3d_${d}.so" ;;
    *) unset SA_PLUGINS_PATH ;;
  esac
  echo "== sa test $t =="
  if "$SA" test "$t"; then echo "PASS $d"; else echo "FAIL $d"; fail=1; fi
done
exit $fail
