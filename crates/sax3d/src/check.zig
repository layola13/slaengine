// check.zig — SAX3D 裁判校验器：封闭词表之上的全部按名/按型检查。
// 每项拒绝都有稳定具名诊断码（SPEC §诊断表）；无静默兜底、无默认值猜测。
// 输入是 AST + 接口表夹具集（按 shader 名），输出诊断集 + 解析产物
// （段 kind/对齐指派，供布局与写入器共用）。

const std = @import("std");
const model = @import("model.zig");
const ifacemod = @import("iface.zig");
const schema = @import("schema_gen.zig");

pub const Resolved = struct {
    section_kind: std.StringHashMap(schema.SectionKind),
    section_align: std.StringHashMap(u32),
};

pub const Ctx = struct {
    alloc: std.mem.Allocator,
    a: *const model.Asset,
    ifaces: *const std.StringHashMap(ifacemod.Iface),
    diags: *model.Diags,
    sections: std.StringHashMap(u64),
    res: Resolved,

    fn secLen(self: *Ctx, name: []const u8) ?u64 { return self.sections.get(name); }
    fn refSection(self: *Ctx, name: []const u8, ctx_kind: []const u8, ctx_name: []const u8) ?u64 {
        const l = self.secLen(name) orelse {
            self.diags.add("Sax3dUnresolvedReference", "{s} '{s}': section '{s}' not declared in binary block", .{ ctx_kind, ctx_name, name });
            return null;
        };
        return l;
    }
    fn useSection(self: *Ctx, name: []const u8, kind: schema.SectionKind, align_: u32) void {
        if (self.res.section_kind.get(name)) |old| {
            if (old != kind) self.diags.add("Sax3dSectionKindConflict", "section '{s}' used as both {s} and {s}", .{ name, @tagName(old), @tagName(kind) });
            return;
        }
        self.res.section_kind.put(name, kind) catch {};
        self.res.section_align.put(name, align_) catch {};
    }
};

fn findByName(comptime T: type, list: []const T, name: []const u8) ?*const T {
    for (list) |*e| { if (std.mem.eql(u8, e.name, name)) return e; }
    return null;
}

fn dupCheck(ctx: *Ctx, comptime T: type, list: []const T, kind: []const u8) void {
    for (list, 0..) |e, i| {
        for (list[0..i]) |o| {
            if (std.mem.eql(u8, o.name, e.name))
                ctx.diags.add("Sax3dDuplicateName", "{s} '{s}' declared twice (names are unique per kind)", .{ kind, e.name });
        }
    }
}

pub fn check(alloc: std.mem.Allocator, a: *const model.Asset, ifaces: *const std.StringHashMap(ifacemod.Iface), diags: *model.Diags) Resolved {
    var ctx = Ctx{
        .alloc = alloc,
        .a = a,
        .ifaces = ifaces,
        .diags = diags,
        .sections = .init(alloc),
        .res = .{ .section_kind = .init(alloc), .section_align = .init(alloc) },
    };
    if (a.binary) |b| {
        for (b.sections.items) |s| {
            if (ctx.sections.contains(s.name))
                diags.add("Sax3dDuplicateName", "section '{s}' declared twice in binary block", .{s.name});
            ctx.sections.put(s.name, s.len) catch {};
        }
    }
    dupCheck(&ctx, model.ShaderDecl, a.shaders.items, "shader");
    dupCheck(&ctx, model.MeshDecl, a.meshes.items, "mesh");
    dupCheck(&ctx, model.SkeletonDecl, a.skeletons.items, "skeleton");
    dupCheck(&ctx, model.ImageDecl, a.images.items, "image");
    dupCheck(&ctx, model.TextureDecl, a.textures.items, "texture");
    dupCheck(&ctx, model.MaterialDecl, a.materials.items, "material");
    dupCheck(&ctx, model.SceneDecl, a.scenes.items, "scene");
    dupCheck(&ctx, model.ClipDecl, a.clips.items, "clip");

    checkMeshes(&ctx);
    checkSkeletons(&ctx);
    checkImages(&ctx);
    checkTextures(&ctx);
    checkMaterials(&ctx);
    checkScenes(&ctx);
    checkSkeletonSceneCross(&ctx);
    checkClips(&ctx);
    checkInputCoverage(&ctx);

    // 未被引用的段：kind = blob（作者自留载荷），align 1。
    if (a.binary) |b| {
        for (b.sections.items) |s| {
            if (!ctx.res.section_kind.contains(s.name)) {
                ctx.res.section_kind.put(s.name, .blob) catch {};
                ctx.res.section_align.put(s.name, 1) catch {};
            }
        }
    }
    return ctx.res;
}

// ---------- 几何层 ----------
fn chanRoleType(chan: []const u8) ?[]const []const u8 {
    // 规范通道的元素类型白名单（SPEC §5.2 定形）
    if (std.mem.eql(u8, chan, "position") or std.mem.eql(u8, chan, "normal")) return &.{ "f32x3" };
    if (std.mem.eql(u8, chan, "tangent")) return &.{ "f32x4" };
    if (std.mem.startsWith(u8, chan, "uv")) return &.{ "f32x2" };
    if (std.mem.eql(u8, chan, "color0")) return &.{ "f32x4", "u8x4" };
    if (std.mem.eql(u8, chan, "joints0")) return &.{ "u16x4" };
    if (std.mem.eql(u8, chan, "weights0")) return &.{ "f32x4" };
    return null;
}

fn checkOneChannel(ctx: *Ctx, mesh_name: []const u8, ch: model.ChannelDecl, count: u64, in_morph: bool) void {
    if (ch.custom) {
        if (model.isCanonChannel(ch.name))
            ctx.diags.add("Sax3dAttrNameReserved", "mesh '{s}': attr name '{s}' is a canonical channel name; use 'channel'", .{ mesh_name, ch.name });
    } else {
        if (!model.isCanonChannel(ch.name)) {
            ctx.diags.add("Sax3dUnknownChannel", "mesh '{s}': channel '{s}' not in canonical set (use 'attr' for custom channels)", .{ mesh_name, ch.name });
            return;
        }
        if (in_morph and !(std.mem.eql(u8, ch.name, "position") or std.mem.eql(u8, ch.name, "normal") or std.mem.eql(u8, ch.name, "tangent"))) {
            ctx.diags.add("Sax3dMorphChannelInvalid", "mesh '{s}': morph channel '{s}' not a delta channel (position/normal/tangent only)", .{ mesh_name, ch.name });
            return;
        }
        if (chanRoleType(ch.name)) |allowed| {
            var ok = false;
            for (allowed) |t| { if (std.mem.eql(u8, t, ch.ty)) ok = true; }
            if (!ok) ctx.diags.add("Sax3dChannelTypeMismatch", "mesh '{s}': channel '{s}' type {s} does not fit its canonical role", .{ mesh_name, ch.name, ch.ty });
        }
    }
    const et = schema.elemType(ch.ty) orelse {
        ctx.diags.add("Sax3dUnknownElemType", "mesh '{s}': channel '{s}' element type '{s}' not in sax3d.sai type table", .{ mesh_name, ch.name, ch.ty });
        return;
    };
    const sl = ctx.refSection(ch.section, "mesh channel", ch.name) orelse return;
    if (count * et.size > sl)
        ctx.diags.add("Sax3dSectionOverflow", "mesh '{s}': channel '{s}' needs {d} x {d}B = {d}B > section '{s}' ({d}B)", .{ mesh_name, ch.name, count, et.size, count * et.size, ch.section, sl });
    ctx.useSection(ch.section, .channel, et.alignment);
}

fn checkMeshes(ctx: *Ctx) void {
    const a = ctx.a;
    for (a.meshes.items) |m| {
        const topos = [_][]const u8{ "triangles", "triangle-strip", "lines", "line-strip", "points" };
        var tok = false;
        for (topos) |t| { if (std.mem.eql(u8, t, m.topology)) tok = true; }
        if (!tok) ctx.diags.add("Sax3dInvalidValue", "mesh '{s}': topology '{s}' not in closed set", .{ m.name, m.topology });
        if (m.vertices == 0) ctx.diags.add("Sax3dInvalidValue", "mesh '{s}': vertices is 0 or undeclared", .{m.name});
        // 通道重名（含 morph 内外分开计：morph 通道与基础通道同名是增量关系，不算重名）
        for (m.channels.items, 0..) |ch, i| {
            for (m.channels.items[0..i]) |o| {
                if (std.mem.eql(u8, o.name, ch.name)) ctx.diags.add("Sax3dDuplicateName", "mesh '{s}': channel '{s}' declared twice", .{ m.name, ch.name });
            }
            checkOneChannel(ctx, m.name, ch, m.vertices, false);
        }
        var has_j = false; var has_w = false;
        for (m.channels.items) |ch| {
            if (std.mem.eql(u8, ch.name, "joints0")) has_j = true;
            if (std.mem.eql(u8, ch.name, "weights0")) has_w = true;
        }
        if (has_j != has_w)
            ctx.diags.add("Sax3dChannelPairing", "mesh '{s}': joints0 and weights0 must appear as a pair", .{m.name});
        for (m.morphs.items, 0..) |mo, i| {
            for (m.morphs.items[0..i]) |o| {
                if (std.mem.eql(u8, o.name, mo.name)) ctx.diags.add("Sax3dDuplicateName", "mesh '{s}': morph '{s}' declared twice", .{ m.name, mo.name });
            }
            for (mo.channels.items) |ch| checkOneChannel(ctx, m.name, ch, m.vertices, true);
        }
        if (m.idx_ty) |ity| {
            if (!std.mem.eql(u8, ity, "u16") and !std.mem.eql(u8, ity, "u32"))
                ctx.diags.add("Sax3dInvalidValue", "mesh '{s}': index type '{s}' not u16/u32", .{ m.name, ity });
            if (ctx.refSection(m.idx_section, "mesh indices", m.name)) |sl| {
                const esz = schema.elemType(ity).?.size;
                if (m.idx_count * esz > sl)
                    ctx.diags.add("Sax3dSectionOverflow", "mesh '{s}': indices {d} x {d}B = {d}B > section '{s}' ({d}B)", .{ m.name, m.idx_count, esz, m.idx_count * esz, m.idx_section, sl });
                ctx.useSection(m.idx_section, .index, schema.elemType(ity).?.alignment);
            }
        }
        if (m.prims.items.len == 0)
            ctx.diags.add("Sax3dInvalidValue", "mesh '{s}': no primitive declared", .{m.name});
        for (m.prims.items, 0..) |pr, i| {
            for (m.prims.items[0..i]) |o| {
                if (std.mem.eql(u8, o.name, pr.name)) ctx.diags.add("Sax3dDuplicateName", "mesh '{s}': primitive '{s}' declared twice", .{ m.name, pr.name });
            }
            if (findByName(model.MaterialDecl, a.materials.items, pr.material) == null)
                ctx.diags.add("Sax3dUnresolvedReference", "mesh '{s}' primitive '{s}': material '{s}' not declared", .{ m.name, pr.name, pr.material });
        }
    }
}

// ---------- 骨骼层 ----------
fn checkSkeletons(ctx: *Ctx) void {
    for (ctx.a.skeletons.items) |sk| {
        for (sk.joints.items, 0..) |j, i| {
            for (sk.joints.items[0..i]) |o| {
                if (std.mem.eql(u8, o.name, j.name)) ctx.diags.add("Sax3dDuplicateName", "skeleton '{s}': joint '{s}' declared twice", .{ sk.name, j.name });
            }
            if (j.parent) |par| {
                if (findByName(model.JointDecl, sk.joints.items, par) == null)
                    ctx.diags.add("Sax3dUnresolvedReference", "skeleton '{s}': joint '{s}' parent '{s}' not a joint of this skeleton", .{ sk.name, j.name, par });
            }
            // 环检：沿 parent 链上溯，步数上限 = 关节数
            var cur: ?[]const u8 = j.parent;
            var steps: usize = 0;
            while (cur) |c| {
                steps += 1;
                if (steps > sk.joints.items.len) {
                    ctx.diags.add("Sax3dJointCycle", "skeleton '{s}': joint '{s}' parent chain cycles", .{ sk.name, j.name });
                    break;
                }
                const jd = findByName(model.JointDecl, sk.joints.items, c) orelse break;
                cur = jd.parent;
            }
        }
        if (sk.ib_section) |sec| {
            if (ctx.refSection(sec, "skeleton", sk.name)) |sl| {
                const need = @as(u64, @intCast(sk.joints.items.len)) * schema.elemType("f32x4x4").?.size;
                if (need > sl)
                    ctx.diags.add("Sax3dSectionOverflow", "skeleton '{s}': inverse_bind needs {d} joints x 64B = {d}B > section '{s}' ({d}B)", .{ sk.name, sk.joints.items.len, need, sec, sl });
                ctx.useSection(sec, .inverse_bind, schema.elemType("f32x4x4").?.alignment);
            }
        } else ctx.diags.add("Sax3dInvalidValue", "skeleton '{s}': inverse_bind section missing", .{sk.name});
    }
}

// ---------- 纹理层 ----------
fn checkImages(ctx: *Ctx) void {
    const fmts = [_][]const u8{ "png", "jpeg", "ktx2", "raw-rgba8", "raw-rgba16f" };
    for (ctx.a.images.items) |im| {
        var fok = false;
        for (fmts) |f| { if (std.mem.eql(u8, f, im.format)) fok = true; }
        if (!fok) ctx.diags.add("Sax3dInvalidValue", "image '{s}': format '{s}' not in closed set", .{ im.name, im.format });
        if (!std.mem.eql(u8, im.color_space, "srgb") and !std.mem.eql(u8, im.color_space, "linear"))
            ctx.diags.add("Sax3dInvalidValue", "image '{s}': color_space '{s}' must be declared srgb|linear (never guessed)", .{ im.name, im.color_space });
        const is_raw = std.mem.startsWith(u8, im.format, "raw-");
        if (im.source_kind == .section) {
            if (ctx.refSection(im.source, "image", im.name)) |sl| {
                if (is_raw) {
                    const sz = im.size orelse {
                        ctx.diags.add("Sax3dInvalidValue", "image '{s}': raw format requires explicit size", .{im.name});
                        continue;
                    };
                    const bpp: u64 = if (std.mem.eql(u8, im.format, "raw-rgba8")) 4 else 8;
                    if (sz[0] * sz[1] * bpp != sl)
                        ctx.diags.add("Sax3dRawImageSizeMismatch", "image '{s}': {s} {d}x{d} = {d}B != section '{s}' ({d}B)", .{ im.name, im.format, sz[0], sz[1], sz[0] * sz[1] * bpp, im.source, sl });
                    ctx.useSection(im.source, .image_raw, 1);
                } else ctx.useSection(im.source, .blob, 1);
            }
        }
    }
}

fn checkTextures(ctx: *Ctx) void {
    for (ctx.a.textures.items) |t| {
        if (findByName(model.ImageDecl, ctx.a.images.items, t.image) == null)
            ctx.diags.add("Sax3dUnresolvedReference", "texture '{s}': image '{s}' not declared", .{ t.name, t.image });
        if (!t.sampler.present) {
            ctx.diags.add("Sax3dMissingSamplerState", "texture '{s}': sampler block missing (sampler state is declared, never guessed)", .{t.name});
            continue;
        }
        // v1 定形：2D 五字段必须全声明（SPEC 登记）。
        const req = .{
            .{ "mag", t.sampler.mag }, .{ "min", t.sampler.min }, .{ "mipmap", t.sampler.mipmap },
            .{ "wrap_u", t.sampler.wrap_u }, .{ "wrap_v", t.sampler.wrap_v },
        };
        inline for (req) |r| {
            if (r[1] == null) ctx.diags.add("Sax3dMissingSamplerState", "texture '{s}': sampler field '{s}' not declared", .{ t.name, r[0] });
        }
        const filt = [_][]const u8{ "nearest", "linear" };
        const mips = [_][]const u8{ "none", "nearest", "linear" };
        const wraps = [_][]const u8{ "clamp", "repeat", "mirror" };
        checkEnum(ctx, "texture", t.name, "mag", t.sampler.mag, &filt);
        checkEnum(ctx, "texture", t.name, "min", t.sampler.min, &filt);
        checkEnum(ctx, "texture", t.name, "mipmap", t.sampler.mipmap, &mips);
        checkEnum(ctx, "texture", t.name, "wrap_u", t.sampler.wrap_u, &wraps);
        checkEnum(ctx, "texture", t.name, "wrap_v", t.sampler.wrap_v, &wraps);
        checkEnum(ctx, "texture", t.name, "wrap_w", t.sampler.wrap_w, &wraps);
    }
}

fn checkEnum(ctx: *Ctx, kind: []const u8, name: []const u8, field: []const u8, val: ?[]const u8, set: []const []const u8) void {
    const v = val orelse return;
    for (set) |s| { if (std.mem.eql(u8, s, v)) return; }
    ctx.diags.add("Sax3dInvalidValue", "{s} '{s}': {s} = '{s}' not in closed value set", .{ kind, name, field, v });
}

// ---------- 材质层（对 SLASL 接口表按名+按型绑定，设计 §6.3 核心纪律） ----------
fn checkMaterials(ctx: *Ctx) void {
    for (ctx.a.materials.items) |mt| {
        if (findByName(model.ShaderDecl, ctx.a.shaders.items, mt.shader) == null) {
            ctx.diags.add("Sax3dUnresolvedReference", "material '{s}': shader '{s}' not declared", .{ mt.name, mt.shader });
            continue;
        }
        if (mt.alpha) |al| {
            if (!std.mem.eql(u8, al, "opaque") and !std.mem.eql(u8, al, "mask") and !std.mem.eql(u8, al, "blend"))
                ctx.diags.add("Sax3dInvalidValue", "material '{s}': state alpha '{s}' not opaque|mask|blend", .{ mt.name, al });
        }
        const iface = ctx.ifaces.get(mt.shader) orelse {
            ctx.diags.add("Sax3dMissingInterfaceFixture", "material '{s}': no interface-table fixture supplied for shader '{s}' (GAP-1: v1 binds against hand-specified fixtures)", .{ mt.name, mt.shader });
            continue;
        };
        for (mt.params.items, 0..) |pr, i| {
            for (mt.params.items[0..i]) |o| {
                if (std.mem.eql(u8, o.name, pr.name)) ctx.diags.add("Sax3dDuplicateName", "material '{s}': param '{s}' assigned twice", .{ mt.name, pr.name });
            }
            const ip = iface.params.get(pr.name) orelse {
                ctx.diags.add("Sax3dUndeclaredParam", "material '{s}': param '{s}' not in shader '{s}' interface params", .{ mt.name, pr.name, mt.shader });
                continue;
            };
            if (!std.mem.eql(u8, ip.ty, pr.lit.typeName()))
                ctx.diags.add("Sax3dParamTypeMismatch", "material '{s}': param '{s}' literal type {s} != interface type {s}", .{ mt.name, pr.name, pr.lit.typeName(), ip.ty });
        }
        // 接口 params 必须被赋值或带默认值，不许静默零值。
        var pit = iface.params.iterator();
        while (pit.next()) |e| {
            var assigned = false;
            for (mt.params.items) |pr| { if (std.mem.eql(u8, pr.name, e.key_ptr.*)) assigned = true; }
            if (!assigned and !e.value_ptr.has_default)
                ctx.diags.add("Sax3dUnboundParam", "material '{s}': interface param '{s}' unassigned and carries no default", .{ mt.name, e.key_ptr.* });
        }
        for (mt.texbinds.items, 0..) |tb, i| {
            for (mt.texbinds.items[0..i]) |o| {
                if (std.mem.eql(u8, o.name, tb.name)) ctx.diags.add("Sax3dDuplicateName", "material '{s}': texture binding '{s}' declared twice", .{ mt.name, tb.name });
            }
            if (!iface.textures.contains(tb.name))
                ctx.diags.add("Sax3dUndeclaredTextureBinding", "material '{s}': texture binding '{s}' is not a sampler param of shader '{s}'", .{ mt.name, tb.name, mt.shader });
            if (findByName(model.TextureDecl, ctx.a.textures.items, tb.texture) == null)
                ctx.diags.add("Sax3dUnresolvedReference", "material '{s}': texture '{s}' not declared", .{ mt.name, tb.texture });
        }
        for (mt.tex_transforms.items) |tt| {
            var bound = false;
            for (mt.texbinds.items) |tb| { if (std.mem.eql(u8, tb.name, tt.name)) bound = true; }
            if (!bound)
                ctx.diags.add("Sax3dUndeclaredTextureBinding", "material '{s}': tex_transform targets '{s}' which is not bound in this material", .{ mt.name, tt.name });
        }
        var tit = iface.textures.keyIterator();
        while (tit.next()) |key| {
            var bound = false;
            for (mt.texbinds.items) |tb| { if (std.mem.eql(u8, tb.name, key.*)) bound = true; }
            if (!bound)
                ctx.diags.add("Sax3dUnboundSamplerParam", "material '{s}': shader sampler param '{s}' left unbound", .{ mt.name, key.* });
        }
    }
}

// ---------- 装配层 ----------
pub const NodeInfo = struct { node: *const model.NodeDecl, parent: ?[]const u8 };

pub fn collectNodes(alloc: std.mem.Allocator, a: *const model.Asset) std.ArrayList(NodeInfo) {
    var out: std.ArrayList(NodeInfo) = .empty;
    for (a.scenes.items) |sc| {
        for (sc.roots.items) |*n| collectNodeRec(alloc, n, null, &out);
    }
    return out;
}
fn collectNodeRec(alloc: std.mem.Allocator, n: *const model.NodeDecl, parent: ?[]const u8, out: *std.ArrayList(NodeInfo)) void {
    out.append(alloc, .{ .node = n, .parent = parent }) catch {};
    for (n.children.items) |*c| collectNodeRec(alloc, c, n.name, out);
}

fn checkScenes(ctx: *Ctx) void {
    const nodes = collectNodes(ctx.alloc, ctx.a);
    for (nodes.items, 0..) |ni, i| {
        for (nodes.items[0..i]) |o| {
            if (std.mem.eql(u8, o.node.name, ni.node.name))
                ctx.diags.add("Sax3dDuplicateName", "node '{s}' declared twice (node names are global)", .{ni.node.name});
        }
        const n = ni.node;
        if (n.transform != null and n.matrix != null)
            ctx.diags.add("Sax3dTransformConflict", "node '{s}': transform (TRS) and matrix are mutually exclusive", .{n.name});
        var mesh: ?*const model.MeshDecl = null;
        if (n.mesh) |mn| {
            mesh = findByName(model.MeshDecl, ctx.a.meshes.items, mn);
            if (mesh == null) ctx.diags.add("Sax3dUnresolvedReference", "node '{s}': mesh '{s}' not declared", .{ n.name, mn });
        }
        if (n.material) |mn| {
            if (findByName(model.MaterialDecl, ctx.a.materials.items, mn) == null)
                ctx.diags.add("Sax3dUnresolvedReference", "node '{s}': material '{s}' not declared", .{ n.name, mn });
            if (mesh) |m| {
                if (m.prims.items.len != 1)
                    ctx.diags.add("Sax3dMaterialOverrideAmbiguous", "node '{s}': material override requires the mesh to have exactly 1 primitive, mesh '{s}' has {d}", .{ n.name, m.name, m.prims.items.len });
            } else ctx.diags.add("Sax3dInvalidValue", "node '{s}': material override without a mesh", .{n.name});
        }
        if (n.skin) |sn| {
            if (findByName(model.SkeletonDecl, ctx.a.skeletons.items, sn) == null)
                ctx.diags.add("Sax3dUnresolvedReference", "node '{s}': skeleton '{s}' not declared", .{ n.name, sn });
            if (mesh) |m| {
                var has_j = false; var has_w = false;
                for (m.channels.items) |ch| {
                    if (std.mem.eql(u8, ch.name, "joints0")) has_j = true;
                    if (std.mem.eql(u8, ch.name, "weights0")) has_w = true;
                }
                if (!has_j or !has_w)
                    ctx.diags.add("Sax3dSkinChannelMissing", "node '{s}': skin '{s}' but mesh '{s}' lacks joints0/weights0 channels", .{ n.name, sn, m.name });
            } else ctx.diags.add("Sax3dInvalidValue", "node '{s}': skin without a mesh", .{n.name});
        }
    }
}

// ---------- 骨骼 × 装配交叉（关节即节点） ----------
fn checkSkeletonSceneCross(ctx: *Ctx) void {
    const nodes = collectNodes(ctx.alloc, ctx.a);
    const parentOf = struct {
        fn get(list: []const NodeInfo, name: []const u8) ??[]const u8 {
            for (list) |ni| { if (std.mem.eql(u8, ni.node.name, name)) return ni.parent; }
            return null;
        }
    };
    for (ctx.a.skeletons.items) |sk| {
        const jointSet = struct {
            fn has(s: *const model.SkeletonDecl, n: []const u8) bool {
                return findByName(model.JointDecl, s.joints.items, n) != null;
            }
        };
        for (sk.joints.items) |j| {
            var found = false;
            for (nodes.items) |ni| { if (std.mem.eql(u8, ni.node.name, j.name)) found = true; }
            if (!found) {
                ctx.diags.add("Sax3dSkinJointNotNode", "skeleton '{s}': joint '{s}' has no same-named node in any scene", .{ sk.name, j.name });
                continue;
            }
            // 最近关节祖先必须等于声明 parent（无关节祖先 <=> parent 为 none）。
            var anc: ??[]const u8 = parentOf.get(nodes.items, j.name);
            var nearest: ?[]const u8 = null;
            var guard: usize = 0;
            while (anc) |a| {
                guard += 1;
                if (guard > nodes.items.len + 1) break;
                const aname = a orelse break;
                if (jointSet.has(&sk, aname)) { nearest = aname; break; }
                anc = parentOf.get(nodes.items, aname);
            }
            const want = j.parent;
            const ok = (want == null and nearest == null) or
                (want != null and nearest != null and std.mem.eql(u8, want.?, nearest.?));
            if (!ok)
                ctx.diags.add("Sax3dJointParentMismatch", "skeleton '{s}': joint '{s}' declares parent '{s}' but nearest joint ancestor in scene is '{s}'", .{
                    sk.name, j.name, want orelse "none", nearest orelse "none",
                });
        }
    }
}

// ---------- 动画层 ----------
fn checkClips(ctx: *Ctx) void {
    const nodes = collectNodes(ctx.alloc, ctx.a);
    for (ctx.a.clips.items) |c| {
        for (c.samplers.items, 0..) |s, i| {
            for (c.samplers.items[0..i]) |o| {
                if (std.mem.eql(u8, o.name, s.name)) ctx.diags.add("Sax3dDuplicateName", "clip '{s}': sampler '{s}' declared twice", .{ c.name, s.name });
            }
            if (!std.mem.eql(u8, s.in_ty, "f32"))
                ctx.diags.add("Sax3dChannelTypeMismatch", "clip '{s}' sampler '{s}': input type '{s}' is not f32 (time axis)", .{ c.name, s.name, s.in_ty });
            if (ctx.refSection(s.in_section, "clip sampler input", s.name)) |sl| {
                if (s.in_count * 4 > sl)
                    ctx.diags.add("Sax3dSectionOverflow", "clip '{s}' sampler '{s}': input {d} x 4B = {d}B > section '{s}' ({d}B)", .{ c.name, s.name, s.in_count, s.in_count * 4, s.in_section, sl });
                ctx.useSection(s.in_section, .anim_input, 4);
            }
            const oet = schema.elemType(s.out_ty) orelse {
                ctx.diags.add("Sax3dUnknownElemType", "clip '{s}' sampler '{s}': output type '{s}' not in sax3d.sai type table", .{ c.name, s.name, s.out_ty });
                continue;
            };
            if (ctx.refSection(s.out_section, "clip sampler output", s.name)) |sl| {
                if (s.out_count * oet.size > sl)
                    ctx.diags.add("Sax3dSectionOverflow", "clip '{s}' sampler '{s}': output {d} x {d}B = {d}B > section '{s}' ({d}B)", .{ c.name, s.name, s.out_count, oet.size, s.out_count * oet.size, s.out_section, sl });
                ctx.useSection(s.out_section, .anim_output, oet.alignment);
            }
            const interps = [_][]const u8{ "step", "linear", "cubic-spline" };
            var iok = false;
            for (interps) |x| { if (std.mem.eql(u8, x, s.interpolation)) iok = true; }
            if (!iok) ctx.diags.add("Sax3dInvalidValue", "clip '{s}' sampler '{s}': interpolation '{s}' not in closed set", .{ c.name, s.name, s.interpolation });
        }
        for (c.channels.items) |ch| {
            var node: ?*const model.NodeDecl = null;
            for (nodes.items) |ni| { if (std.mem.eql(u8, ni.node.name, ch.node)) node = ni.node; }
            if (node == null) {
                ctx.diags.add("Sax3dClipTargetMissing", "clip '{s}': channel targets node '{s}' which is not in any scene", .{ c.name, ch.node });
                continue;
            }
            var smp: ?*const model.AnimSampler = null;
            for (c.samplers.items) |*s| { if (std.mem.eql(u8, s.name, ch.sampler)) smp = s; }
            if (smp == null) {
                ctx.diags.add("Sax3dClipSamplerMissing", "clip '{s}': channel references sampler '{s}' not declared in this clip", .{ c.name, ch.sampler });
                continue;
            }
            const s = smp.?;
            const paths = [_][]const u8{ "translation", "rotation", "scale", "weights" };
            var pok = false;
            for (paths) |x| { if (std.mem.eql(u8, x, ch.path)) pok = true; }
            if (!pok) { ctx.diags.add("Sax3dInvalidValue", "clip '{s}': channel path '{s}' not in closed set", .{ c.name, ch.path }); continue; }
            // output 类型对 path
            const want_ty: []const u8 = if (std.mem.eql(u8, ch.path, "translation") or std.mem.eql(u8, ch.path, "scale")) "f32x3"
                else if (std.mem.eql(u8, ch.path, "rotation")) "quat"
                else "f32";
            if (!std.mem.eql(u8, s.out_ty, want_ty) and !(std.mem.eql(u8, ch.path, "rotation") and std.mem.eql(u8, s.out_ty, "f32x4")))
                ctx.diags.add("Sax3dChannelTypeMismatch", "clip '{s}': channel path '{s}' needs output type {s}, sampler '{s}' has {s}", .{ c.name, ch.path, want_ty, s.name, s.out_ty });
            // 计数关系：weights 的每键帧元素数 = target mesh 的 morph 数
            var per_key: u64 = 1;
            if (std.mem.eql(u8, ch.path, "weights")) {
                const m = if (node.?.mesh) |mn| findByName(model.MeshDecl, ctx.a.meshes.items, mn) else null;
                if (m == null or m.?.morphs.items.len == 0) {
                    ctx.diags.add("Sax3dInvalidValue", "clip '{s}': weights channel targets node '{s}' whose mesh has no morph targets", .{ c.name, ch.node });
                    continue;
                }
                per_key = @intCast(m.?.morphs.items.len);
            }
            const factor: u64 = if (std.mem.eql(u8, s.interpolation, "cubic-spline")) 3 else 1;
            if (s.out_count != s.in_count * per_key * factor)
                ctx.diags.add("Sax3dAnimCountMismatch", "clip '{s}' sampler '{s}': output count {d} != input {d} x per-key {d} x interp factor {d}", .{ c.name, s.name, s.out_count, s.in_count, per_key, factor });
        }
    }
}

// ---------- mesh 通道喂 shader @input（规范映射 + 类型，设计 §4/§6.1） ----------
fn canonicalInputType(input_name: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, input_name, "position") or std.mem.eql(u8, input_name, "normal")) return "vec3";
    if (std.mem.eql(u8, input_name, "tangent")) return "vec4";
    if (std.mem.eql(u8, input_name, "uv") or std.mem.startsWith(u8, input_name, "uv")) return "vec2";
    if (std.mem.eql(u8, input_name, "color")) return "vec4";
    if (std.mem.eql(u8, input_name, "joints")) return "uvec4";
    if (std.mem.eql(u8, input_name, "weights")) return "vec4";
    return null;
}

fn checkInputCoverage(ctx: *Ctx) void {
    for (ctx.a.meshes.items) |m| {
        // 该 mesh 实际会被哪些 shader 绘制：其 primitive 材质的 shader 集合。
        var seen_shaders: std.ArrayList([]const u8) = .empty;
        for (m.prims.items) |pr| {
            const mt = findByName(model.MaterialDecl, ctx.a.materials.items, pr.material) orelse continue;
            const iface = ctx.ifaces.get(mt.shader) orelse continue;
            var dup = false;
            for (seen_shaders.items) |s| { if (std.mem.eql(u8, s, mt.shader)) dup = true; }
            if (dup) continue;
            seen_shaders.append(ctx.alloc, mt.shader) catch {};
            var iit = iface.inputs.iterator();
            while (iit.next()) |e| {
                const iname = e.key_ptr.*;
                const ity = e.value_ptr.*;
                var feeder: ?*const model.ChannelDecl = null;
                for (m.channels.items) |*ch| {
                    if (ch.custom) continue;
                    const mapped = model.channelInputName(ch.name) orelse continue;
                    if (std.mem.eql(u8, mapped, iname)) feeder = ch;
                }
                if (feeder == null) {
                    ctx.diags.add("Sax3dInputNotFed", "mesh '{s}': no channel feeds shader '{s}' input '{s}'", .{ m.name, mt.shader, iname });
                    continue;
                }
                if (canonicalInputType(iname)) |want| {
                    if (!std.mem.eql(u8, want, ity))
                        ctx.diags.add("Sax3dChannelTypeMismatch", "mesh '{s}': shader '{s}' input '{s}' has type {s}, format canonical type is {s}", .{ m.name, mt.shader, iname, ity, want });
                }
                // 通道元素类型与输入类型的相容性由角色白名单 + 上行检查保证；
                // 此处再核通道实际类型对输入的等价类：
                const ch = feeder.?;
                const ok = blk: {
                    if (std.mem.eql(u8, iname, "position") or std.mem.eql(u8, iname, "normal")) break :blk std.mem.eql(u8, ch.ty, "f32x3");
                    if (std.mem.eql(u8, iname, "tangent") or std.mem.eql(u8, iname, "weights")) break :blk std.mem.eql(u8, ch.ty, "f32x4");
                    if (std.mem.eql(u8, iname, "color")) break :blk std.mem.eql(u8, ch.ty, "f32x4") or std.mem.eql(u8, ch.ty, "u8x4");
                    if (std.mem.eql(u8, iname, "joints")) break :blk std.mem.eql(u8, ch.ty, "u16x4");
                    break :blk std.mem.eql(u8, ch.ty, "f32x2"); // uv 家族
                };
                if (!ok)
                    ctx.diags.add("Sax3dChannelTypeMismatch", "mesh '{s}': channel '{s}' type {s} cannot feed shader input '{s}: {s}'", .{ m.name, ch.name, ch.ty, iname, ity });
            }
        }
    }
}
