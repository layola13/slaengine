#!/bin/bash
# run_tests.sh — SAX3D v1 全量验收（自包含，可重跑）。
# 口径：每项断言以退出码 + 期望串双确认；失败名字集非空即整体 FAIL。
set -u
cd "$(dirname "$0")/.."
ROOT=$PWD
ZIG=${ZIG:-$HOME/workspace/local-sa/zig17/zig}
B=$ROOT/work/build-out/bin
W=$ROOT/work/tests-run
rm -rf "$W"; mkdir -p "$W"
PASS=0; FAILED=""
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAILED="$FAILED $1"; echo "FAIL  $1"; }
# expect_ok <name> <cmd...> : rc==0
expect_ok() { local n=$1; shift; if "$@" >"$W/$n.log" 2>&1; then ok "$n"; else bad "$n (see work/tests-run/$n.log)"; fi; }
# expect_diag <name> <code> <cmd...> : rc!=0 且输出含码且不含 panic
expect_diag() { local n=$1 code=$2; shift 2; "$@" >"$W/$n.log" 2>&1; local rc=$?;
  if [ $rc -ne 0 ] && grep -q "$code" "$W/$n.log" && ! grep -qi "panic" "$W/$n.log"; then ok "$n"; else bad "$n (rc=$rc, want diag $code; see log)"; fi; }

echo "== 0. schema 单一真理源新鲜度 =="
"$ZIG" run tools/gen_schema.zig -- sax3d.sai "$W/schema_gen.zig" >/dev/null 2>&1
if diff -q "$W/schema_gen.zig" src/schema_gen.zig >/dev/null; then ok schema-fresh; else bad schema-fresh; fi

echo "== 1. 构建 =="
expect_ok build "$ZIG" build --prefix "$ROOT/work/build-out"

echo "== 2. 立方体例双形 =="
expect_ok cube-check "$B/sax3dc" check examples/cube.sax3d --iface PbrStd=examples/pbr_std.iface.txt
for want in "positions: kind channel, offset 256, len 288" "normals: kind channel, offset 544, len 288" \
            "uvs: kind channel, offset 832, len 192" "indices: kind index, offset 1024, len 72" \
            "checker: kind image_raw, offset 1096, len 16" "spin_times: kind anim_input, offset 1112, len 8" \
            "spin_rots: kind anim_output, offset 1120, len 32" "payload end 1152"; do
  grep -q "$want" "$W/cube-check.log" && ok "cube-offset[$want]" || bad "cube-offset[$want]"
done
"$B/genpayload" "$W/cube" positions:288 normals:288 uvs:192 indices:72 checker:16 spin_times:8 spin_rots:32 >/dev/null 2>&1
expect_ok cube-build "$B/sax3dc" build examples/cube.sax3d --payload-dir "$W/cube" --out "$W/cube.saxb3d" --iface PbrStd=examples/pbr_std.iface.txt
expect_ok cube-pack "$B/sax3dc" pack examples/cube.sax3d --bin "$W/cube.saxb3d" --out "$W/cube.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt
"$B/sax3dc" pack examples/cube.sax3d --bin "$W/cube.saxb3d" --out "$W/cube2.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt >/dev/null 2>&1
cmp -s "$W/cube.sax3dp" "$W/cube2.sax3dp" && ok cube-pack-deterministic || bad cube-pack-deterministic
"$B/readback" split examples/cube.sax3d "$W/cube.saxb3d" --iface PbrStd=examples/pbr_std.iface.txt > "$W/cube.split.digest" 2>"$W/cube.split.log"; rc1=$?
"$B/readback" packed "$W/cube.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt > "$W/cube.packed.digest" 2>"$W/cube.packed.log"; rc2=$?
[ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && ok cube-readback || bad cube-readback
[ -s "$W/cube.split.digest" ] && diff -q <(sort "$W/cube.split.digest") <(sort "$W/cube.packed.digest") >/dev/null && ok cube-dualform-equivalent || bad cube-dualform-equivalent

echo "== 3. 蒙皮动画例双形 =="
expect_ok hero-check "$B/sax3dc" check examples/hero.sax3d --iface Skinned=examples/skinned.iface.txt
for want in "hero_pos: kind channel, offset 384, len 48" "hero_joints: kind channel, offset 512, len 32" \
            "hero_weights: kind channel, offset 544, len 64" "hero_idx: kind index, offset 608, len 12" \
            "rig_ib: kind inverse_bind, offset 668, len 128" "wave_rots: kind anim_output, offset 808, len 48" \
            "payload end 868"; do
  grep -q "$want" "$W/hero-check.log" && ok "hero-offset[$want]" || bad "hero-offset[$want]"
done
"$B/genpayload" "$W/hero" hero_pos:48 hero_nrm:48 hero_uv:32 hero_joints:32 hero_weights:64 hero_idx:12 hero_morph_pos:48 rig_ib:128 wave_times:12 wave_rots:48 wave_weights:12 >/dev/null 2>&1
expect_ok hero-build "$B/sax3dc" build examples/hero.sax3d --payload-dir "$W/hero" --out "$W/hero.saxb3d" --iface Skinned=examples/skinned.iface.txt
expect_ok hero-pack "$B/sax3dc" pack examples/hero.sax3d --bin "$W/hero.saxb3d" --out "$W/hero.sax3dp" --iface Skinned=examples/skinned.iface.txt
"$B/readback" split examples/hero.sax3d "$W/hero.saxb3d" --iface Skinned=examples/skinned.iface.txt > "$W/hero.split.digest" 2>/dev/null; rc1=$?
"$B/readback" packed "$W/hero.sax3dp" --iface Skinned=examples/skinned.iface.txt > "$W/hero.packed.digest" 2>/dev/null; rc2=$?
[ $rc1 -eq 0 ] && [ $rc2 -eq 0 ] && ok hero-readback || bad hero-readback
[ -s "$W/hero.split.digest" ] && diff -q <(sort "$W/hero.split.digest") <(sort "$W/hero.packed.digest") >/dev/null && ok hero-dualform-equivalent || bad hero-dualform-equivalent

echo "== 4. 负例语料 =="
python3 tests/gen_corpus.py >/dev/null
expect_ok neg-control "$B/sax3dc" check tests/valid_control.sax3d --iface S=tests/neg.iface.txt
expect_diag neg-nofixture Sax3dMissingInterfaceFixture "$B/sax3dc" check tests/valid_control.sax3d
declare -A NEG=(
 [neg_unresolved_ref]=Sax3dUnresolvedReference [neg_undeclared_param]=Sax3dUndeclaredParam
 [neg_param_type_mismatch]=Sax3dParamTypeMismatch [neg_unbound_param]=Sax3dUnboundParam
 [neg_undeclared_texture_binding]=Sax3dUndeclaredTextureBinding [neg_unbound_sampler]=Sax3dUnboundSamplerParam
 [neg_channel_type_mismatch]=Sax3dChannelTypeMismatch [neg_input_not_fed]=Sax3dInputNotFed
 [neg_clip_target_missing]=Sax3dClipTargetMissing [neg_skin_joint_not_node]=Sax3dSkinJointNotNode
 [neg_duplicate_name]=Sax3dDuplicateName [neg_unknown_declaration]=Sax3dUnknownDeclaration
 [neg_section_overflow]=Sax3dSectionOverflow [neg_unknown_channel]=Sax3dUnknownChannel
 [neg_transform_conflict]=Sax3dTransformConflict [neg_material_override_ambiguous]=Sax3dMaterialOverrideAmbiguous
 [neg_anim_count_mismatch]=Sax3dAnimCountMismatch [neg_raw_image_size]=Sax3dRawImageSizeMismatch
 [neg_sampler_state_missing]=Sax3dMissingSamplerState [neg_section_kind_conflict]=Sax3dSectionKindConflict
 [neg_joint_parent_mismatch]=Sax3dJointParentMismatch [neg_parse_error]=Sax3dParseError
)
for f in "${!NEG[@]}"; do
  expect_diag "$f" "${NEG[$f]}" "$B/sax3dc" check "tests/negative/$f.sax3d" --iface S=tests/neg.iface.txt
done

echo "== 5. 二进制损坏语料（readback 面） =="
cp "$W/cube.sax3dp" "$W/corrupt_magic.sax3dp";    printf 'X' | dd of="$W/corrupt_magic.sax3dp" bs=1 seek=0 conv=notrunc 2>/dev/null
cp "$W/cube.sax3dp" "$W/corrupt_version.sax3dp";  printf '\x09' | dd of="$W/corrupt_version.sax3dp" bs=1 seek=8 conv=notrunc 2>/dev/null
cp "$W/cube.sax3dp" "$W/corrupt_flags.sax3dp";    printf '\x01' | dd of="$W/corrupt_flags.sax3dp" bs=1 seek=16 conv=notrunc 2>/dev/null
cp "$W/cube.sax3dp" "$W/corrupt_nameoff.sax3dp";  printf '\xff\xff\xff\x7f' | dd of="$W/corrupt_nameoff.sax3dp" bs=1 seek=32 conv=notrunc 2>/dev/null
head -c 100 "$W/cube.sax3dp" > "$W/corrupt_trunc.sax3dp"
expect_diag corrupt-magic Sax3dBadMagic "$B/readback" packed "$W/corrupt_magic.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt
expect_diag corrupt-version Sax3dUnsupportedVersion "$B/readback" packed "$W/corrupt_version.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt
expect_diag corrupt-flags Sax3dBadFlags "$B/readback" packed "$W/corrupt_flags.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt
expect_diag corrupt-nameoff Sax3dNameTableMismatch "$B/readback" packed "$W/corrupt_nameoff.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt
expect_diag corrupt-truncated Sax3dTruncatedFile "$B/readback" packed "$W/corrupt_trunc.sax3dp" --iface PbrStd=examples/pbr_std.iface.txt

echo "== 6. 垃圾输入健壮性（永不 panic） =="
head -c 512 /dev/urandom > "$W/garbage.sax3d"
"$B/sax3dc" check "$W/garbage.sax3d" >"$W/garbage.log" 2>&1; rc=$?
[ $rc -ne 0 ] && ! grep -qi "panic" "$W/garbage.log" && ok garbage-robust || bad garbage-robust
: > "$W/empty.sax3d"
"$B/sax3dc" check "$W/empty.sax3d" >"$W/empty.log" 2>&1; rc=$?
[ $rc -ne 0 ] && ! grep -qi "panic" "$W/empty.log" && ok empty-robust || bad empty-robust
# 载荷长度不符
"$B/genpayload" "$W/badpayload" positions:100 >/dev/null 2>&1
expect_diag payload-len Sax3dPayloadLengthMismatch "$B/sax3dc" build examples/cube.sax3d --payload-dir "$W/badpayload" --out "$W/x.saxb3d" --iface PbrStd=examples/pbr_std.iface.txt

echo "== 7. 体积对拍参照件 =="
expect_ok genref "$B/genref" "$W/cube" "$W/ref"
[ -f "$W/ref/cube.gltf" ] && [ -f "$W/ref/cube.glb" ] && ok ref-artefacts || bad ref-artefacts
{
  echo "SIZE text_bytes=$(stat -c%s examples/cube.sax3d)"
  echo "SIZE text_bytes_stripped=$(sed -e 's|//.*$||' examples/cube.sax3d | tr -d '[:space:]' | wc -c)"
  echo "SIZE split_bin=$(stat -c%s "$W/cube.saxb3d")"
  echo "SIZE packed_total=$(stat -c%s "$W/cube.sax3dp")"
  grep -o 'assembly: kind assembly, offset [0-9]*, len [0-9]*' "$W/cube-pack.log" | sed 's/.*len /SIZE packed_assembly_len=/'
  grep -o 'name table [0-9]*B' "$W/cube-pack.log" | sed 's/name table /SIZE packed_nametab_len=/; s/B$//'
  grep 'REF ' "$W/genref.log"
  echo "SIZE ref_gltf_json=$(stat -c%s "$W/ref/cube.gltf")"
  echo "SIZE ref_gltf_bin=$(stat -c%s "$W/ref/cube.bin")"
  echo "SIZE ref_gltf_total=$(( $(stat -c%s "$W/ref/cube.gltf") + $(stat -c%s "$W/ref/cube.bin") ))"
  echo "SIZE ref_glb_total=$(stat -c%s "$W/ref/cube.glb")"
} | tee "$W/sizes.txt"

echo
echo "RESULT: $PASS passed; FAILED SET:${FAILED:- (empty)}"
[ -z "$FAILED" ]
