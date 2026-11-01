#!/usr/bin/env python3
# fox_equiv.py — Fox 往返等价对拍（Phase 2 验收专用）。
# 用法: fox_equiv.py <orig Fox.glb> <exported .gltf> <exported .bin>
# 比较：几何 accessor 字节、蒙皮 IBM/关节数、动画通道集合与采样字节、
# 材质因子、节点名集、图像字节。NORMAL 为派生通道（台账已记），只验存在与计数。

import json, struct, sys
from collections import Counter

def load_gltf(path):
    d = open(path, 'rb').read()
    if d[:4] == b'glTF':
        jl, = struct.unpack('<I', d[12:16])
        j = json.loads(d[20:20+jl])
        bl, = struct.unpack('<I', d[20+jl:24+jl])
        return j, d[28+jl:28+jl+bl]
    return json.loads(d), None

def acc_bytes(j, binb, ai):
    a = j['accessors'][ai]
    bv = j['bufferViews'][a['bufferView']]
    cs = {5120:1,5121:1,5122:2,5123:2,5125:4,5126:4}[a['componentType']]
    tc = {'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    es = cs*tc
    stride = bv.get('byteStride', es)
    base = bv.get('byteOffset',0)+a.get('byteOffset',0)
    return b''.join(binb[base+i*stride: base+i*stride+es] for i in range(a['count']))

fails = []
def chk(name, cond, extra=''):
    print(('PASS ' if cond else 'FAIL ') + name + ((' ' + extra) if extra else ''))
    if not cond: fails.append(name)

orig, obin = load_gltf(sys.argv[1])
exp, _ = load_gltf(sys.argv[2])
ebin = open(sys.argv[3], 'rb').read()

op = orig['meshes'][0]['primitives'][0]
ep = exp['meshes'][0]['primitives'][0]
for attr in ['POSITION', 'TEXCOORD_0', 'JOINTS_0', 'WEIGHTS_0']:
    chk(f'attr {attr} bytes', acc_bytes(orig, obin, op['attributes'][attr]) == acc_bytes(exp, ebin, ep['attributes'][attr]))
chk('derived NORMAL present', 'NORMAL' in ep['attributes'] and exp['accessors'][ep['attributes']['NORMAL']]['count'] == orig['accessors'][op['attributes']['POSITION']]['count'])
chk('no indices both sides', 'indices' not in op and 'indices' not in ep)

os_, es = orig['skins'][0], exp['skins'][0]
chk('skin joints count', len(os_['joints']) == len(es['joints']), f"{len(os_['joints'])} vs {len(es['joints'])}")
chk('skin IBM bytes', acc_bytes(orig, obin, os_['inverseBindMatrices']) == acc_bytes(exp, ebin, es['inverseBindMatrices']))

def anim_map(j, binb):
    out = {}
    names = [n.get('name') for n in j['nodes']]
    for a in j['animations']:
        chans = {}
        for c in a['channels']:
            s = a['samplers'][c['sampler']]
            key = (names[c['target']['node']], c['target']['path'])
            chans[key] = (acc_bytes(j, binb, s['input']), acc_bytes(j, binb, s['output']), s.get('interpolation','LINEAR'))
        out[a.get('name')] = chans
    return out
oa, ea = anim_map(orig, obin), anim_map(exp, ebin)
chk('animation names', set(oa) == set(ea), str(sorted(oa)))
for an in oa:
    chk(f'anim {an} channel keys', set(oa[an]) == set(ea.get(an, {})), f"{len(oa[an])} vs {len(ea.get(an, {}))}")
    bad = [k for k in oa[an] if k in ea.get(an, {}) and oa[an][k] != ea[an][k]]
    chk(f'anim {an} sampler bytes+interp', not bad, str(bad[:3]))

om, em = orig['materials'][0], exp['materials'][0]
opbr, epbr = om['pbrMetallicRoughness'], em['pbrMetallicRoughness']
chk('metallicFactor', opbr.get('metallicFactor', 1.0) == epbr.get('metallicFactor', 1.0))
chk('roughnessFactor', opbr.get('roughnessFactor', 1.0) == epbr.get('roughnessFactor', 1.0))
chk('baseColorTexture present', 'baseColorTexture' in epbr)
chk('shader in extras', em.get('extras', {}).get('sax3d_shader') == 'StdPbrSkinned')
chk('node name sets', set(n.get('name') for n in orig['nodes']) == set(n.get('name') for n in exp['nodes']),
    f"{len(orig['nodes'])} vs {len(exp['nodes'])}")
obv = orig['bufferViews'][orig['images'][0]['bufferView']]
obytes = obin[obv.get('byteOffset',0): obv.get('byteOffset',0)+obv['byteLength']]
ebv = exp['bufferViews'][exp['images'][0]['bufferView']]
ebytes = ebin[ebv.get('byteOffset',0): ebv.get('byteOffset',0)+ebv['byteLength']]
chk('image bytes', obytes == ebytes, f"{len(obytes)} vs {len(ebytes)}")

print('FOX-EQUIV:', 'ALL PASS' if not fails else f'FAILED {fails}')
sys.exit(1 if fails else 0)
