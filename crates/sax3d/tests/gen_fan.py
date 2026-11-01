#!/usr/bin/env python3
# gen_fan.py — SPEC D-9（triangle-fan 文码订正）转换器回归语料生成器。
# 产出两个 TRIANGLE_FAN (mode 6) 最小 glTF 到 argv[1] 目录：
#   FanQuad: 索引扇——5 顶点（中心 + 4 环点，坐标互异便于逐项核），
#            扇索引 [0,1,2,3,4]，期望展开 [0,1,2, 0,2,3, 0,3,4]。
#   FanFree: 非索引扇——5 顶点直序为扇，期望转换器合成索引缓冲后
#            展开为同一序列 [0,1,2, 0,2,3, 0,3,4]。
# 两例均带 NORMAL (0,0,1) 与一个标准 PBR 材质（无贴图），使转换
# 产物绑 StdPbrNtNu（夹具 converter/fixtures/std_pbr_nt_nu.iface.txt）。
# 仅用标准库。
import json, os, struct, sys

def build(indexed):
    buf = bytearray()
    views = []
    def add(data):
        while len(buf) % 4:
            buf.append(0)
        off = len(buf)
        buf.extend(data)
        views.append((off, len(data)))
        return len(views) - 1
    f32 = lambda xs: struct.pack('<%df' % len(xs), *xs)
    u16 = lambda xs: struct.pack('<%dH' % len(xs), *xs)
    if indexed:
        pos = [0,0,0,  1,0,0,  2,1,0,  1,2,0,  0,1,0]
    else:
        pos = [0,0,1,  2,0,1,  3,1,1,  2,3,1,  0,2,1]
    nrm = [0,0,1] * 5
    v_pos = add(f32(pos))
    v_nrm = add(f32(nrm))
    acc = [
        {"bufferView": v_pos, "componentType": 5126, "count": 5, "type": "VEC3",
         "min": [min(pos[0::3]), min(pos[1::3]), min(pos[2::3])],
         "max": [max(pos[0::3]), max(pos[1::3]), max(pos[2::3])]},
        {"bufferView": v_nrm, "componentType": 5126, "count": 5, "type": "VEC3"},
    ]
    prim = {"attributes": {"POSITION": 0, "NORMAL": 1},
            "material": 0, "mode": 6}
    if indexed:
        v_idx = add(u16([0, 1, 2, 3, 4]))
        acc.append({"bufferView": v_idx, "componentType": 5123,
                    "count": 5, "type": "SCALAR"})
        prim["indices"] = 2
    doc = {
        "asset": {"version": "2.0", "generator": "gen_fan.py"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "FanNode", "mesh": 0}],
        "meshes": [{"name": "FanMesh", "primitives": [prim]}],
        "materials": [{"name": "FanMat", "pbrMetallicRoughness": {
            "baseColorFactor": [0.8, 0.7, 0.6, 1.0],
            "metallicFactor": 0.0, "roughnessFactor": 1.0}}],
        "buffers": [{"byteLength": len(buf)}],
        "bufferViews": [{"buffer": 0, "byteOffset": o, "byteLength": n}
                        for (o, n) in views],
        "accessors": acc,
    }
    return doc, bytes(buf)

def main():
    outdir = sys.argv[1]
    os.makedirs(outdir, exist_ok=True)
    for stem, indexed in (("FanQuad", True), ("FanFree", False)):
        doc, binb = build(indexed)
        doc["buffers"][0]["uri"] = stem + ".bin"
        with open(os.path.join(outdir, stem + ".bin"), "wb") as f:
            f.write(binb)
        with open(os.path.join(outdir, stem + ".gltf"), "w") as f:
            json.dump(doc, f, indent=1)
    print("gen_fan: wrote FanQuad/FanFree to", outdir)

if __name__ == "__main__":
    main()
