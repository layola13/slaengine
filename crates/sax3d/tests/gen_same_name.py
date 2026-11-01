#!/usr/bin/env python3
# gen_same_name.py — BLENDER.md B1 同名对应约定的转换器校验语料生成器。
# 产出两个最小蒙皮 glTF（JSON + 单 BIN）到 argv[1] 目录：
#   SkinMin: 关节 Hip(根)/Knee(子)，clip Wave 的通道以名字指向 Knee。
#   SkinDup: 两关节同名为 Bone（跨 armature 合并的典型撞名），通道指向
#            第二个 Bone 节点——期望转换器去重改名为 Bone_2 且 joint 与
#            通道同步改名（台账 LEDGER SYNTH 一行可查）。
# 几何为单三角形，权重全给关节 0；IBM 单位阵。仅用标准库。
import json, os, struct, sys

def build(joint_names, clip_target_idx):
    buf = bytearray()
    views = []   # (offset, length)
    def add(data):
        while len(buf) % 4:
            buf.append(0)
        off = len(buf)
        buf.extend(data)
        views.append((off, len(data)))
        return len(views) - 1
    f32 = lambda xs: struct.pack('<%df' % len(xs), *xs)
    u16 = lambda xs: struct.pack('<%dH' % len(xs), *xs)
    v_pos = add(f32([0,0,0,  1,0,0,  0,1,0]))
    v_uv  = add(f32([0,0,  1,0,  0,1]))
    v_jnt = add(u16([0,0,0,0,  0,0,0,0,  0,0,0,0]))
    v_wgt = add(f32([1,0,0,0,  1,0,0,0,  1,0,0,0]))
    v_idx = add(u16([0,1,2]))
    ident = [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]
    v_ibm = add(f32(ident + ident))
    v_tim = add(f32([0.0, 1.0]))
    v_rot = add(f32([0,0,0,1,  0,0,0,1]))
    acc = [
        {"bufferView": v_pos, "componentType": 5126, "count": 3, "type": "VEC3",
         "min": [0,0,0], "max": [1,1,0]},
        {"bufferView": v_uv,  "componentType": 5126, "count": 3, "type": "VEC2"},
        {"bufferView": v_jnt, "componentType": 5123, "count": 3, "type": "VEC4"},
        {"bufferView": v_wgt, "componentType": 5126, "count": 3, "type": "VEC4"},
        {"bufferView": v_idx, "componentType": 5123, "count": 3, "type": "SCALAR"},
        {"bufferView": v_ibm, "componentType": 5126, "count": 2, "type": "MAT4"},
        {"bufferView": v_tim, "componentType": 5126, "count": 2, "type": "SCALAR",
         "min": [0.0], "max": [1.0]},
        {"bufferView": v_rot, "componentType": 5126, "count": 2, "type": "VEC4"},
    ]
    doc = {
        "asset": {"version": "2.0", "generator": "gen_same_name.py"},
        "scene": 0,
        "scenes": [{"nodes": [0, 2]}],
        "nodes": [
            {"name": joint_names[0], "children": [1], "translation": [0, 1, 0]},
            {"name": joint_names[1], "translation": [0, 0.5, 0]},
            {"name": "Body", "mesh": 0, "skin": 0},
        ],
        "meshes": [{"name": "Tri", "primitives": [{
            "attributes": {"POSITION": 0, "TEXCOORD_0": 1,
                           "JOINTS_0": 2, "WEIGHTS_0": 3},
            "indices": 4, "material": 0}]}],
        "materials": [{"name": "Mat", "pbrMetallicRoughness": {
            "baseColorFactor": [1, 1, 1, 1],
            "metallicFactor": 0.0, "roughnessFactor": 1.0}}],
        "skins": [{"name": "Armature", "joints": [0, 1],
                   "inverseBindMatrices": 5}],
        "animations": [{"name": "Wave",
            "samplers": [{"input": 6, "output": 7, "interpolation": "LINEAR"}],
            "channels": [{"sampler": 0, "target": {
                "node": clip_target_idx, "path": "rotation"}}]}],
        "buffers": [{"byteLength": len(buf)}],
        "bufferViews": [{"buffer": 0, "byteOffset": o, "byteLength": n}
                        for (o, n) in views],
        "accessors": acc,
    }
    return doc, bytes(buf)

def main():
    outdir = sys.argv[1]
    os.makedirs(outdir, exist_ok=True)
    for stem, names, tgt in (("SkinMin", ["Hip", "Knee"], 1),
                             ("SkinDup", ["Bone", "Bone"], 1)):
        doc, binb = build(names, tgt)
        doc["buffers"][0]["uri"] = stem + ".bin"
        with open(os.path.join(outdir, stem + ".bin"), "wb") as f:
            f.write(binb)
        with open(os.path.join(outdir, stem + ".gltf"), "w") as f:
            json.dump(doc, f, indent=1)
    print("gen_same_name: wrote SkinMin/SkinDup to", outdir)

if __name__ == "__main__":
    main()
