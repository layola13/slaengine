#!/bin/bash
# run_convert.sh — SAX3D <-> glTF 转换器验收（Phase 2）。
# 前置： 先跑 tests/run_tests.sh 产出二进制与两例的拆分二进制；
# 本脚本独立在 work/convert-run 下工作。
set -u
cd "$(dirname "$0")/.."
ROOT=$PWD
B=$ROOT/work/build-out/bin
W=$ROOT/work/convert-run
rm -rf "$W"; mkdir -p "$W"
PASS=0; FAILED=""
ok()  { PASS=$((PASS+1)); echo "PASS  $1"; }
bad() { FAILED="$FAILED $1"; echo "FAIL  $1"; }

FIX=converter/fixtures

echo "== A. 真实样本 Fox.glb: glTF -> SAX3D -> glTF =="
"$B/convert" to-sax3d converter/samples/Fox.glb "$W/fox" --fixtures-dir $FIX >"$W/fox_fwd.log" 2>"$W/fox_fwd.err"
[ $? -eq 0 ] && ok fox-import || bad fox-import
grep -q "LEDGER APPROX mesh 'fox1': NORMAL absent; normals derived" "$W/fox_fwd.log" && ok fox-ledger-normals || bad fox-ledger-normals
grep -q "LEDGER LOSS skeleton 'skeleton_0': skin.skeleton root hint" "$W/fox_fwd.log" && ok fox-ledger-skelhint || bad fox-ledger-skelhint
grep -q "bound to shader 'StdPbrSkinned'" "$W/fox_fwd.log" && ok fox-ledger-shaderbind || bad fox-ledger-shaderbind
"$B/sax3dc" build "$W/fox/Fox.sax3d" --payload-dir "$W/fox/payload" --out "$W/fox/Fox.saxb3d" \
  --iface StdPbrSkinned=$FIX/std_pbr_skinned.iface.txt >"$W/fox_build.log" 2>&1
[ $? -eq 0 ] && ok fox-referee-build || bad fox-referee-build
"$B/convert" to-gltf "$W/fox/Fox.sax3d" "$W/fox/Fox.saxb3d" "$W/fox-back" \
  --iface StdPbrSkinned=$FIX/std_pbr_skinned.iface.txt >"$W/fox_back.log" 2>"$W/fox_back.err"
[ $? -eq 0 ] && ok fox-export || bad fox-export
python3 tests/fox_equiv.py converter/samples/Fox.glb "$W/fox-back/Fox.gltf" "$W/fox-back/Fox.bin" >"$W/fox_equiv.log" 2>&1
[ $? -eq 0 ] && ok fox-roundtrip-equiv || bad fox-roundtrip-equiv
python3 -c "
import struct, json
d = open('$W/fox-back/Fox.glb','rb').read()
jl, = struct.unpack('<I', d[12:16]); total, = struct.unpack('<I', d[8:12])
assert d[:4] == b'glTF' and total == len(d)
json.loads(d[20:20+jl]); print('glb ok')
" >/dev/null 2>&1 && ok fox-glb-structure || bad fox-glb-structure

echo "== B. 立方体例: SAX3D -> glTF -> SAX3D =="
"$B/genpayload" "$W/cube" positions:288 normals:288 uvs:192 indices:72 checker:16 spin_times:8 spin_rots:32 >/dev/null 2>&1
"$B/sax3dc" build examples/cube.sax3d --payload-dir "$W/cube" --out "$W/cube.saxb3d" --iface PbrStd=examples/pbr_std.iface.txt >/dev/null 2>&1
"$B/readback" split examples/cube.sax3d "$W/cube.saxb3d" --iface PbrStd=examples/pbr_std.iface.txt >"$W/cube.orig.digest" 2>/dev/null
"$B/convert" to-gltf examples/cube.sax3d "$W/cube.saxb3d" "$W/cube-gltf" \
  --iface PbrStd=examples/pbr_std.iface.txt --std-shader PbrStd >"$W/cube_fwd.log" 2>"$W/cube_fwd.err"
[ $? -eq 0 ] && ok cube-export || bad cube-export
grep -q "standard shader 'PbrStd' represented by the PBR parameter set" "$W/cube_fwd.log" && ok cube-ledger-shader || bad cube-ledger-shader
grep -q "raw-rgba8 losslessly PNG-encoded" "$W/cube_fwd.log" && ok cube-ledger-png || bad cube-ledger-png
"$B/convert" to-sax3d "$W/cube-gltf/CubeDemo.gltf" "$W/cube-back" --fixtures-dir $FIX >"$W/cube_back.log" 2>"$W/cube_back.err"
[ $? -eq 0 ] && ok cube-reimport || bad cube-reimport
"$B/sax3dc" build "$W/cube-back/CubeDemo.sax3d" --payload-dir "$W/cube-back/payload" --out "$W/cube-back/CubeDemo.saxb3d" \
  --iface StdPbr=$FIX/std_pbr.iface.txt >/dev/null 2>&1
[ $? -eq 0 ] && ok cube-rebuild || bad cube-rebuild
"$B/readback" split "$W/cube-back/CubeDemo.sax3d" "$W/cube-back/CubeDemo.saxb3d" --iface StdPbr=$FIX/std_pbr.iface.txt >"$W/cube.new.digest" 2>/dev/null
# 段以 (kind,len,sha256) 多重集比（段名由转换器按规范重生，非语义）；
# 声明按名比；图像段（raw->PNG 表示变换）与 shader 名（标准重绑）按映射表除外
{ grep '^digest-decl' "$W/cube.orig.digest" | grep -v 'digest-decl shader' | sort;
  grep '^digest-section' "$W/cube.orig.digest" | grep -v 'digest-section checker ' | awk '{print $3, $4, $5}' | sort; } > "$W/cube.orig.f"
{ grep '^digest-decl' "$W/cube.new.digest" | grep -v 'digest-decl shader' | sort;
  grep '^digest-section' "$W/cube.new.digest" | grep -v 'digest-section CheckerImg_data ' | awk '{print $3, $4, $5}' | sort; } > "$W/cube.new.f"
[ -s "$W/cube.orig.f" ] && diff -q "$W/cube.orig.f" "$W/cube.new.f" >/dev/null && ok cube-roundtrip-digest || bad cube-roundtrip-digest
# 像素级等价：导出 PNG 解码 == 原始 raw 像素
python3 -c "
import json, struct, zlib, sys
j = json.load(open('$W/cube-gltf/CubeDemo.gltf'))
binb = open('$W/cube-gltf/CubeDemo.bin','rb').read()
bv = j['bufferViews'][j['images'][0]['bufferView']]
png = binb[bv.get('byteOffset',0): bv.get('byteOffset',0)+bv['byteLength']]
assert png[:8] == b'\x89PNG\r\n\x1a\n'
pos = 8; idat = b''
while pos < len(png):
    ln, typ = struct.unpack('>I4s', png[pos:pos+8])
    if typ == b'IDAT': idat += png[pos+8:pos+8+ln]
    pos += 12 + ln
raw = zlib.decompress(idat)
pixels = b''.join(raw[y*9+1:(y+1)*9] for y in range(2))
orig = open('$W/cube/checker.bin','rb').read()
assert pixels == orig, 'pixel mismatch'
print('pixels identical')
" >/dev/null 2>&1 && ok cube-pixel-equiv || bad cube-pixel-equiv

echo "== C. 蒙皮动画例: SAX3D -> glTF -> SAX3D =="
"$B/genpayload" "$W/hero" hero_pos:48 hero_nrm:48 hero_uv:32 hero_joints:32 hero_weights:64 hero_idx:12 hero_morph_pos:48 rig_ib:128 wave_times:12 wave_rots:48 wave_weights:12 >/dev/null 2>&1
"$B/sax3dc" build examples/hero.sax3d --payload-dir "$W/hero" --out "$W/hero.saxb3d" --iface Skinned=examples/skinned.iface.txt >/dev/null 2>&1
"$B/readback" split examples/hero.sax3d "$W/hero.saxb3d" --iface Skinned=examples/skinned.iface.txt >"$W/hero.orig.digest" 2>/dev/null
"$B/convert" to-gltf examples/hero.sax3d "$W/hero.saxb3d" "$W/hero-gltf" \
  --iface Skinned=examples/skinned.iface.txt --std-shader Skinned >"$W/hero_fwd.log" 2>"$W/hero_fwd.err"
[ $? -eq 0 ] && ok hero-export || bad hero-export
grep -q "param 'tint' has no glTF PBR counterpart" "$W/hero_fwd.log" && ok hero-ledger-tint-loss || bad hero-ledger-tint-loss
grep -q "texture binding 'skin_map' has no glTF PBR slot" "$W/hero_fwd.log" && ok hero-ledger-skinmap-loss || bad hero-ledger-skinmap-loss
grep -q "state depth_write=true has no glTF core counterpart" "$W/hero_fwd.log" && ok hero-ledger-depthwrite-loss || bad hero-ledger-depthwrite-loss
python3 -c "
import json
j = json.load(open('$W/hero-gltf/HeroDemo.gltf'))
m = j['materials'][0]
assert m['extras']['sax3d_shader'] == 'Skinned' and m['extras']['sax3d_depth_write'] is True
assert j['meshes'][0]['extras']['targetNames'] == ['Smile']
assert j['animations'][0]['channels'][1]['target']['path'] == 'weights'
print('hero gltf content ok')
" >/dev/null 2>&1 && ok hero-gltf-content || bad hero-gltf-content
"$B/convert" to-sax3d "$W/hero-gltf/HeroDemo.gltf" "$W/hero-back" --fixtures-dir $FIX >"$W/hero_back.log" 2>"$W/hero_back.err"
[ $? -eq 0 ] && ok hero-reimport || bad hero-reimport
"$B/sax3dc" build "$W/hero-back/HeroDemo.sax3d" --payload-dir "$W/hero-back/payload" --out "$W/hero-back/HeroDemo.saxb3d" \
  --iface StdPbrSkinnedNt=$FIX/std_pbr_skinned_nt.iface.txt >/dev/null 2>&1
[ $? -eq 0 ] && ok hero-rebuild || bad hero-rebuild
"$B/readback" split "$W/hero-back/HeroDemo.sax3d" "$W/hero-back/HeroDemo.saxb3d" --iface StdPbrSkinnedNt=$FIX/std_pbr_skinned_nt.iface.txt >"$W/hero.new.digest" 2>/dev/null
# 段以 (kind,len,sha256) 多重集比；声明按名比；
# 图像（外部文件->内嵌段）与 shader 名（标准重绑）按映射表除外
{ grep '^digest-decl' "$W/hero.orig.digest" | grep -v 'digest-decl shader' | sort;
  grep '^digest-section' "$W/hero.orig.digest" | grep -v 'digest-section HeroTexImg ' | awk '{print $3, $4, $5}' | sort; } > "$W/hero.orig.f"
{ grep '^digest-decl' "$W/hero.new.digest" | grep -v 'digest-decl shader' | sort;
  grep '^digest-section' "$W/hero.new.digest" | grep -v 'digest-section HeroTexImg_data ' | awk '{print $3, $4, $5}' | sort; } > "$W/hero.new.f"
[ -s "$W/hero.orig.f" ] && diff -q "$W/hero.orig.f" "$W/hero.new.f" >/dev/null && ok hero-roundtrip-digest || bad hero-roundtrip-digest
# 图像字节守恒：原文件哈希 == 再进口段载荷哈希
H1=$(sha256sum examples/hero_tex.png | cut -d' ' -f1)
H2=$(sha256sum "$W/hero-back/payload/HeroTexImg_data.bin" | cut -d' ' -f1)
[ "$H1" = "$H2" ] && ok hero-image-bytes-preserved || bad hero-image-bytes-preserved

echo "== D. 同名对应约定 (BLENDER.md B1): 关节名 == 节点名 == 通道目标名 =="
python3 tests/gen_same_name.py "$W/samename" >/dev/null 2>&1
"$B/convert" to-sax3d "$W/samename/SkinMin.gltf" "$W/skinmin" --fixtures-dir $FIX >"$W/skinmin.log" 2>"$W/skinmin.err"
[ $? -eq 0 ] && ok skinmin-import || bad skinmin-import
grep -q "joint Knee { parent: Hip; }" "$W/skinmin/SkinMin.sax3d" && ok skinmin-joint-parent || bad skinmin-joint-parent
grep -q "channel { node: Knee; path: rotation" "$W/skinmin/SkinMin.sax3d" && ok skinmin-channel-target || bad skinmin-channel-target
"$B/sax3dc" build "$W/skinmin/SkinMin.sax3d" --payload-dir "$W/skinmin/payload" --out "$W/skinmin/SkinMin.saxb3d" \
  --iface StdPbrSkinnedNt=$FIX/std_pbr_skinned_nt.iface.txt >"$W/skinmin_build.log" 2>&1
[ $? -eq 0 ] && ok skinmin-referee-build || bad skinmin-referee-build
"$B/convert" to-sax3d "$W/samename/SkinDup.gltf" "$W/skindup" --fixtures-dir $FIX >"$W/skindup.log" 2>"$W/skindup.err"
[ $? -eq 0 ] && ok skindup-import || bad skindup-import
grep -q "LEDGER SYNTH name for node\[1\] sanitised/deduped 'Bone' -> 'Bone_2'" "$W/skindup.log" && ok skindup-ledger-dedupe || bad skindup-ledger-dedupe
grep -q "joint Bone_2 { parent: Bone; }" "$W/skindup/SkinDup.sax3d" && ok skindup-joint-renamed || bad skindup-joint-renamed
grep -q "channel { node: Bone_2; path: rotation" "$W/skindup/SkinDup.sax3d" && ok skindup-channel-renamed || bad skindup-channel-renamed

echo "== E. triangle fan 订正 (SPEC D-9, 文从码): 入向展开 + 出向永不产 fan =="
python3 tests/gen_fan.py "$W/fansrc" >/dev/null 2>&1
# E1 索引扇: glTF(mode 6) -> SAX3D(triangles + 展开索引) -> 裁判 -> glTF(mode 4)
"$B/convert" to-sax3d "$W/fansrc/FanQuad.gltf" "$W/fanquad" --fixtures-dir $FIX >"$W/fanquad.log" 2>"$W/fanquad.err"
[ $? -eq 0 ] && ok fanquad-import || bad fanquad-import
grep -q "LEDGER APPROX mesh 'FanMesh': TRIANGLE_FAN expanded to triangle list (lossless, SPEC D-9)" "$W/fanquad.log" && ok fanquad-ledger-expand || bad fanquad-ledger-expand
grep -q "topology: triangles;" "$W/fanquad/FanQuad.sax3d" && ! grep -q "triangle-fan" "$W/fanquad/FanQuad.sax3d" && ok fanquad-topology || bad fanquad-topology
"$B/sax3dc" build "$W/fanquad/FanQuad.sax3d" --payload-dir "$W/fanquad/payload" --out "$W/fanquad/FanQuad.saxb3d" \
  --iface StdPbrNtNu=$FIX/std_pbr_nt_nu.iface.txt >"$W/fanquad_build.log" 2>&1
[ $? -eq 0 ] && ok fanquad-referee-build || bad fanquad-referee-build
"$B/convert" to-gltf "$W/fanquad/FanQuad.sax3d" "$W/fanquad/FanQuad.saxb3d" "$W/fanquad-back" \
  --iface StdPbrNtNu=$FIX/std_pbr_nt_nu.iface.txt >"$W/fanquad_back.log" 2>"$W/fanquad_back.err"
[ $? -eq 0 ] && ok fanquad-export || bad fanquad-export
python3 tests/fan_equiv.py "$W/fansrc/FanQuad.gltf" "$W/fansrc/FanQuad.bin" "$W/fanquad" FanQuad indexed \
  "$W/fanquad-back/FanQuad.gltf" "$W/fanquad-back/FanQuad.bin" >"$W/fanquad_equiv.log" 2>&1
[ $? -eq 0 ] && ok fanquad-equiv || bad fanquad-equiv
# E2 非索引扇: 合成索引缓冲后同样展开
"$B/convert" to-sax3d "$W/fansrc/FanFree.gltf" "$W/fanfree" --fixtures-dir $FIX >"$W/fanfree.log" 2>"$W/fanfree.err"
[ $? -eq 0 ] && ok fanfree-import || bad fanfree-import
python3 tests/fan_equiv.py "$W/fansrc/FanFree.gltf" "$W/fansrc/FanFree.bin" "$W/fanfree" FanFree free >"$W/fanfree_equiv.log" 2>&1
[ $? -eq 0 ] && ok fanfree-equiv || bad fanfree-equiv
"$B/sax3dc" build "$W/fanfree/FanFree.sax3d" --payload-dir "$W/fanfree/payload" --out "$W/fanfree/FanFree.saxb3d" \
  --iface StdPbrNtNu=$FIX/std_pbr_nt_nu.iface.txt >"$W/fanfree_build.log" 2>&1
[ $? -eq 0 ] && ok fanfree-referee-build || bad fanfree-referee-build
# E3 出向守门: 声明 triangle-fan 的 SAX3D 在裁判处以 Sax3dInvalidValue 被拒, 不产出
"$B/genpayload" "$W/ctrl" pos:36 uv:24 idx:12 img:16 times:8 rots:32 ib:64 >/dev/null 2>&1
"$B/sax3dc" build tests/valid_control.sax3d --payload-dir "$W/ctrl" --out "$W/ctrl.saxb3d" --iface S=tests/neg.iface.txt >/dev/null 2>&1
sed 's/^mesh M {/mesh M {\n    topology: triangle-fan;/' tests/valid_control.sax3d > "$W/ctrl_fan.sax3d"
"$B/convert" to-gltf "$W/ctrl_fan.sax3d" "$W/ctrl.saxb3d" "$W/ctrl-fan-out" --iface S=tests/neg.iface.txt >"$W/ctrl_fan.log" 2>&1
[ $? -ne 0 ] && grep -q "Sax3dInvalidValue" "$W/ctrl_fan.log" && grep -q "topology 'triangle-fan' not in closed set" "$W/ctrl_fan.log" && ok fan-export-refused || bad fan-export-refused
# E4 出向产物值集扫描: 本套件全部出口产物 primitive mode 不得含 6
python3 -c "
import json, struct
files = ['$W/fox-back/Fox.glb', '$W/cube-gltf/CubeDemo.gltf', '$W/hero-gltf/HeroDemo.gltf', '$W/fanquad-back/FanQuad.gltf']
modes = set()
for f in files:
    d = open(f, 'rb').read()
    if d[:4] == b'glTF':
        jl, = struct.unpack('<I', d[12:16]); j = json.loads(d[20:20+jl])
    else:
        j = json.loads(d)
    for m in j.get('meshes', []):
        for p in m.get('primitives', []):
            modes.add(p.get('mode', 4))
assert modes, 'no primitives scanned'
assert 6 not in modes, 'TRIANGLE_FAN (mode 6) found in export products'
print('export modes seen:', sorted(modes))
" >"$W/nofan_scan.log" 2>&1
[ $? -eq 0 ] && ok nofan-scan || bad nofan-scan

echo
echo "RESULT: $PASS passed; FAILED SET:${FAILED:- (empty)}"
[ -z "$FAILED" ]
