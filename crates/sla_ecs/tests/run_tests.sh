#!/bin/bash
# sla_ecs per-file test caliber runner — the project's own caliber
# (source README, "Running"): every .sla file in the library, tests and
# examples directories is run individually:
#     SA_PLUGIN_DEV=1 sa sla test <file>
# with two documented exceptions that run on the SA backend instead of
# the default backend (whole-file SAB issues on record for these two in
# the SLA plugin's docs):
#     parallel_iterator.sla, task_pool_builder.sla  ->  --test-backend sa
#
# Usage:
#   bash tests/run_tests.sh [tree-root] [layout] [outdir]
#     tree-root  default: the crate root (parent dir of this script)
#     layout     crate (src/ tests/ examples/) | orig (lib/ tests/ examples/)
#                default: crate
#     outdir     default: <tree-root>/work/test-results
#   Env: ECS_TEST_FILES=<file>  restrict the run to the listed relpaths
#        (one per line; used to shard a run across tree copies — the
#        caliber applied to each listed file is unchanged).
#        ECS_FILE_TIMEOUT=<sec>  per-file timeout, default 600.
#
# Outputs in outdir: per-file logs under logs/, results.tsv
# (relpath, rc, result-line) and names.txt — the failing-name set:
# one "relpath :: test-name" line per named failing test, or
# "relpath :: <file-level>" when the file failed before naming tests
# (compile/import errors, timeouts). Exit code is 1 iff names.txt is
# non-empty. (File-level entries deliberately carry no rc: the set is
# compared across trees, and rc is environment metadata — it is kept
# per file in results.tsv.)
set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TREE=${1:-$(dirname "$SCRIPT_DIR")}
LAYOUT=${2:-crate}
OUT=${3:-$TREE/work/test-results}
TIMEOUT=${ECS_FILE_TIMEOUT:-600}

cd "$TREE" || exit 2
rm -rf .sla-cache
export SLA_NO_FRESHNESS_CACHE=1
export SA_PLUGIN_DEV=${SA_PLUGIN_DEV:-1}
mkdir -p "$OUT/logs"

case "$LAYOUT" in
  crate) DIRS="src tests examples" ;;
  orig)  DIRS="lib tests examples" ;;
  *) echo "unknown layout: $LAYOUT" >&2; exit 2 ;;
esac

if [ -n "${ECS_TEST_FILES:-}" ]; then
  LIST=$(cat "$ECS_TEST_FILES")
else
  LIST=$(for d in $DIRS; do ls "$d"/*.sla 2>/dev/null; done)
fi

: > "$OUT/results.tsv"
: > "$OUT/names.txt"
total=0; passed=0
for f in $LIST; do
  total=$((total+1))
  extra=""
  case "$(basename "$f")" in
    parallel_iterator.sla|task_pool_builder.sla) extra="--test-backend sa" ;;
  esac
  log="$OUT/logs/$(echo "$f" | tr '/' '_').log"
  timeout "$TIMEOUT" sa sla test "$f" $extra > "$log" 2>&1
  rc=$?
  rline=$(grep -m1 "test result:" "$log" || true)
  printf '%s\t%s\t%s\n' "$f" "$rc" "$rline" >> "$OUT/results.tsv"
  if [ "$rc" -eq 0 ] && echo "$rline" | grep -q "test result: ok"; then
    passed=$((passed+1))
  else
    # Named failing tests, when the runner prints them.
    grep -E "^test .+ \.\.\. FAILED" "$log" | sed 's/^test //; s/ \.\.\. FAILED$//' | \
      while IFS= read -r tname; do printf '%s :: %s\n' "$f" "$tname" >> "$OUT/names.txt"; done
    if ! grep -qF "$f :: " "$OUT/names.txt"; then
      printf '%s :: <file-level>\n' "$f" >> "$OUT/names.txt"
    fi
  fi
done
sort -o "$OUT/names.txt" "$OUT/names.txt"
echo "files=$total passed=$passed failed=$((total-passed)) failing-names=$(wc -l < "$OUT/names.txt")"
[ ! -s "$OUT/names.txt" ]
