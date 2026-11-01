#!/usr/bin/env python3
# fan_equiv.py — SPEC D-9 fan 展开几何等价核查（逐项，非抽样）。
# 用法: fan_equiv.py <src.gltf> <src.bin> <conv_outdir> <stem> <indexed|free>
#                    [export.gltf export.bin]
# 核查:
#   1. 源 primitive mode 必须为 6 (TRIANGLE_FAN)，扇序按源索引（indexed）
#      或顶点直序（free）取；
#   2. 转换产物 <stem>.sax3d 写 topology: triangles 且全文无 triangle-fan；
#      vertices 数与源 POSITION count 一致；
#   3. 产物 position 通道段字节 == 源 POSITION accessor 字节（逐字节）；
#   4. 产物 indices 段逐项 == 扇展开期望 [i0,i1,i2, i0,i2,i3, ...]，
#      count == 3(n-2)；
#   5. 若给出口产物：其 primitive mode 必须为 4 (TRIANGLES，永不 6)，
#      indices 逐项与展开期望一致，POSITION 字节与源一致。
import json, os, re, struct, sys

def acc_bytes(doc, binb, ai):
    a = doc["accessors"][ai]
    bv = doc["bufferViews"][a["bufferView"]]
    comp_n = {5121: 1, 5123: 2, 5125: 4, 5126: 4}[a["componentType"]]
    ty_n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    n = a["count"] * comp_n * ty_n
    off = bv.get("byteOffset", 0)
    return binb[off:off + n], a

def acc_u16(doc, binb, ai):
    raw, a = acc_bytes(doc, binb, ai)
    ct = a["componentType"]
    if ct == 5123:
        return list(struct.unpack('<%dH' % a["count"], raw))
    if ct == 5125:
        return list(struct.unpack('<%dI' % a["count"], raw))
    raise AssertionError("indices componentType %d" % ct)

def expand(fan):
    out = []
    for k in range(1, len(fan) - 1):
        out += [fan[0], fan[k], fan[k + 1]]
    return out

def main():
    src_gltf, src_bin, outdir, stem, mode = sys.argv[1:6]
    doc = json.load(open(src_gltf))
    binb = open(src_bin, "rb").read()
    prim = doc["meshes"][0]["primitives"][0]
    assert prim.get("mode", 4) == 6, "source primitive is not TRIANGLE_FAN"
    pos_raw, pos_acc = acc_bytes(doc, binb, prim["attributes"]["POSITION"])
    vcount = pos_acc["count"]
    if mode == "indexed":
        fan = acc_u16(doc, binb, prim["indices"])
    else:
        assert "indices" not in prim, "free sample must be non-indexed"
        fan = list(range(vcount))
    expected = expand(fan)
    assert len(expected) == 3 * (len(fan) - 2) and expected

    text = open(os.path.join(outdir, stem + ".sax3d")).read()
    assert "topology: triangles;" in text, "converted topology is not triangles"
    assert "triangle-fan" not in text, "converted text still mentions triangle-fan"
    mv = re.search(r"vertices (\d+);", text)
    assert mv and int(mv.group(1)) == vcount, "vertex count mismatch"

    msec = re.search(r"channel position : f32x3 @ (\w+);", text)
    assert msec, "position channel not found"
    got_pos = open(os.path.join(outdir, "payload", msec.group(1) + ".bin"), "rb").read()
    assert got_pos == pos_raw, "position bytes differ from source accessor"

    midx = re.search(r"indices u16 @ (\w+) count (\d+);", text)
    assert midx, "indices declaration not found"
    assert int(midx.group(2)) == len(expected), \
        "index count %s != expected %d" % (midx.group(2), len(expected))
    raw = open(os.path.join(outdir, "payload", midx.group(1) + ".bin"), "rb").read()
    got = list(struct.unpack('<%dH' % (len(raw) // 2), raw))
    for i, (g, e) in enumerate(zip(got, expected)):
        assert g == e, "expanded index[%d] = %d, expected %d" % (i, g, e)
    assert len(got) == len(expected)

    if len(sys.argv) > 6:
        eg, eb = sys.argv[6], sys.argv[7]
        edoc = json.load(open(eg))
        ebin = open(eb, "rb").read()
        eprim = edoc["meshes"][0]["primitives"][0]
        assert eprim.get("mode", 4) == 4, \
            "export mode is %s, must be TRIANGLES(4), never FAN(6)" % eprim.get("mode", 4)
        egot = acc_u16(edoc, ebin, eprim["indices"])
        assert egot == expected, "export indices differ from fan expansion"
        epos, _ = acc_bytes(edoc, ebin, eprim["attributes"]["POSITION"])
        assert epos == pos_raw, "export positions differ from source"

    print("fan equiv ok (%s): %d verts byte-identical; fan %s -> triangles %s item-identical"
          % (mode, vcount, fan, expected))

if __name__ == "__main__":
    main()
