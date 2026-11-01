#!/bin/bash
# SLASL P2 acceptance harness — run ON a Colab rig (source rig.sh first).
# Fresh byte-diffs only; never trusts a previous run's outputs.
# Usage: bash run_tests.sh <build-dir-on-box>   (dir containing src/, shaders/, golden/)
set -u
cd "$1" || exit 2
rm -rf .sla-cache slasl out
sa build-exe src/slasl.sla -o slasl > /tmp/slasl_build.log 2>&1
brc=$?
if [ $brc -ne 0 ]; then echo "BUILD FAIL rc=$brc"; head -5 /tmp/slasl_build.log; exit 1; fi
echo "build ok"
fails=0
# gate 1: phase-1 bundle, 8 products byte-exact
./slasl out shaders/base.slasl shaders/tint.slasl || { echo "RUN FAIL bundle"; exit 1; }
for f in golden/*; do
  n=$(basename "$f")
  if cmp -s "$f" "out/$n"; then echo "PASS $n"; else echo "DIFF $n"; fails=$((fails+1)); fi
done
# gate 2 samples (filled in as targets land): each samples/<name>/ holds
# input .slasl files + a `target` file naming the --target id; golden in
# samples_golden/<name>/
if [ -d samples ]; then
  for d in samples/*/; do
    name=$(basename "$d")
    tgt=$(cat "$d/target")
    rm -rf "sout_$name"
    ./slasl --target "$tgt" "sout_$name" "$d"*.slasl > /tmp/slasl_sample.log 2>&1
    if [ $? -ne 0 ]; then echo "SAMPLE RUN FAIL $name"; cat /tmp/slasl_sample.log; fails=$((fails+1)); continue; fi
    for f in "samples_golden/$name"/*; do
      n=$(basename "$f")
      if cmp -s "$f" "sout_$name/$n"; then echo "PASS sample $name/$n"; else echo "DIFF sample $name/$n"; fails=$((fails+1)); fi
    done
  done
fi
# gate 3 negatives: each neg/*.slasl must fail with exit 1 and print its
# expected diagnostic (the file's first line is `// expect: <substring>`)
if [ -d neg ]; then
  for f in neg/*.slasl; do
    case "$f" in *.2.slasl) continue;; esac
    exp=$(head -1 "$f" | sed 's|^// expect: ||')
    base=$(basename "$f" .slasl)
    extra=""
    if [ -f "neg/$base.2.slasl" ]; then extra="neg/$base.2.slasl"; fi
    case "$base" in
      tgt_*)
        tgt=$(echo "$base" | sed 's|^tgt_\([a-z-]*\)_.*|\1|')
        rm -rf neg_out
        out=$(./slasl --target "$tgt" neg_out "$f" $extra 2>&1)
        rc=$?
        ;;
      *)
        out=$(./slasl --check "$f" $extra 2>&1)
        rc=$?
        ;;
    esac
    if [ $rc -ne 1 ]; then echo "NEG FAIL $f rc=$rc (want 1)"; fails=$((fails+1)); continue; fi
    case "$out" in
      *"$exp"*) echo "PASS neg $(basename $f)" ;;
      *) echo "NEG FAIL $f missing diagnostic [$exp] got: $out"; fails=$((fails+1)) ;;
    esac
  done
  # control: a valid file must pass --check with exit 0
  ./slasl --check shaders/base.slasl > /dev/null 2>&1
  if [ $? -ne 0 ]; then echo "NEG CONTROL FAIL"; fails=$((fails+1)); else echo "PASS neg control"; fi
fi
echo "fails=$fails"
[ $fails -eq 0 ]
