#!/usr/bin/env python3
# gen_corpus.py — 生成 SAX3D 负例语料（验收专用）。
# 一份合法基线 valid_control.sax3d + 每诊断一处单点变异。
# 期望诊断码见 run_tests.sh 的 NEG 表（文件名 -> 码）。

import os, sys

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "negative")
os.makedirs(OUT, exist_ok=True)
CTRL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "valid_control.sax3d")

BASE = """asset NegBase version 1;

binary "neg.saxb3d" {
    section pos 36;
    section uv 24;
    section idx 12;
    section img 16;
    section times 8;
    section rots 32;
    section ib 64;
}

mesh M {
    vertices 3;
    channel position : f32x3 @ pos;
    channel uv0 : f32x2 @ uv;
    indices u16 @ idx count 6;
    primitive p { material: Mat; }
}

image Img {
    source @ img;
    format raw-rgba8;
    size 2 2;
    color_space srgb;
}

texture Tex {
    image: Img;
    sampler { mag: linear; min: linear; mipmap: none; wrap_u: clamp; wrap_v: clamp; }
}

shader S: slasl "s.slasl";

material Mat {
    shader: S;
    param good_f = 0.5;
    param good_v = [1.0, 1.0, 1.0, 1.0];
    texture map_a: Tex;
}

skeleton Sk {
    joint Root { parent: none; }
    inverse_bind @ ib;
}

scene Sc {
    node N1 {
        mesh: M;
        node Root { }
    }
}

clip C {
    sampler A {
        input:  f32  @ times count 2;
        output: quat @ rots  count 2;
        interpolation: linear;
    }
    channel { node: N1; path: rotation; sampler: A; }
}
"""

def w(name, text):
    with open(os.path.join(OUT, name), "w") as f:
        f.write(text)

def mut(name, old, new, count=1):
    assert BASE.count(old) >= 1, (name, old)
    w(name, BASE.replace(old, new, count))

with open(CTRL, "w") as f:
    f.write(BASE)

mut("neg_unresolved_ref.sax3d", "primitive p { material: Mat; }", "primitive p { material: Nope; }")
mut("neg_undeclared_param.sax3d", "    param good_f = 0.5;", "    param good_f = 0.5;\n    param bogus = 1.0;")
mut("neg_param_type_mismatch.sax3d", "param good_f = 0.5;", "param good_f = [1.0, 2.0];")
mut("neg_unbound_param.sax3d", "    param good_f = 0.5;\n", "")
mut("neg_undeclared_texture_binding.sax3d", "    texture map_a: Tex;", "    texture map_a: Tex;\n    texture bogus_map: Tex;")
mut("neg_unbound_sampler.sax3d", "    texture map_a: Tex;\n", "")
mut("neg_channel_type_mismatch.sax3d", "channel position : f32x3 @ pos;", "channel position : f32x2 @ pos;")
mut("neg_input_not_fed.sax3d", "    channel uv0 : f32x2 @ uv;\n", "")
mut("neg_clip_target_missing.sax3d", "channel { node: N1;", "channel { node: Ghost;")
mut("neg_skin_joint_not_node.sax3d", "joint Root { parent: none; }", "joint RootX { parent: none; }")
mut("neg_duplicate_name.sax3d", "image Img {", "mesh M {\n    vertices 1;\n    channel position : f32x3 @ pos;\n    primitive q { material: Mat; }\n}\n\nimage Img {")
mut("neg_unknown_declaration.sax3d", "clip C {", "widget W { }\n\nclip C {")
mut("neg_section_overflow.sax3d", "section pos 36;", "section pos 24;")
mut("neg_unknown_channel.sax3d", "    channel uv0 : f32x2 @ uv;", "    channel uv0 : f32x2 @ uv;\n    channel bogus : f32x3 @ pos;")
mut("neg_transform_conflict.sax3d", "    node N1 {\n        mesh: M;", "    node N1 {\n        mesh: M;\n        transform { t: [0.0, 0.0, 0.0]; }\n        matrix: [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0];")
mut("neg_material_override_ambiguous.sax3d", "    primitive p { material: Mat; }", "    primitive p { material: Mat; }\n    primitive p2 { material: Mat; }")
# 上一变异还需节点覆盖才触发歧义诊断：
p = os.path.join(OUT, "neg_material_override_ambiguous.sax3d")
t = open(p).read().replace("    node N1 {\n        mesh: M;", "    node N1 {\n        mesh: M;\n        material: Mat;")
open(p, "w").write(t)

mut("neg_anim_count_mismatch.sax3d", "section rots 32;", "section rots 48;")
p = os.path.join(OUT, "neg_anim_count_mismatch.sax3d")
t = open(p).read().replace("output: quat @ rots  count 2;", "output: quat @ rots  count 3;")
open(p, "w").write(t)

mut("neg_raw_image_size.sax3d", "size 2 2;", "size 3 2;")
mut("neg_sampler_state_missing.sax3d", "    sampler { mag: linear; min: linear; mipmap: none; wrap_u: clamp; wrap_v: clamp; }\n", "")
mut("neg_section_kind_conflict.sax3d", "input:  f32  @ times count 2;", "input:  f32  @ pos count 2;")

# 关节父子不一致：双关节骨骼 + 场景里 Child 不在 Root 之下（自带二进制块）
w("neg_joint_parent_mismatch.sax3d", BASE.replace("section ib 64;", "section ib 128;")
    .replace("    joint Root { parent: none; }",
             "    joint Root { parent: none; }\n    joint Child { parent: Root; }")
    .replace("    node N1 {\n        mesh: M;\n        node Root { }\n    }",
             "    node N1 {\n        mesh: M;\n        node Root { }\n        node Child { }\n    }"))

# 语法层损坏：截断文件（期望 Sax3dParseError 且不 panic）
w("neg_parse_error.sax3d", "asset Broken version 1;\n\nmesh M {\n    vertices")

print("corpus written to", OUT)
