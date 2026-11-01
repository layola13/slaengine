// packform.zig — 编译形组装发射器（打包器用）。
// 把 AST 发射为规范文本：与创作形同一文法，但一切声明名/引用名替换为
// 名表索引 #<n>（名字只在名表出现一次）；shader 的 .slasl 路径不入合并形
// （按名入册，见 SPEC §F-2 补定）；字段序与空白全规范化，同 AST 必同字节。

const std = @import("std");
const model = @import("model.zig");
const layout = @import("layout.zig");

pub const Emitter = struct {
    alloc: std.mem.Allocator,
    nt: *const layout.NameTable,
    out: std.Io.Writer.Allocating,

    fn w(self: *Emitter) *std.Io.Writer { return &self.out.writer; }
    fn ref(self: *Emitter, name: []const u8) []const u8 { return self.nt.refText(self.alloc, name); }
    fn num(self: *Emitter, v: f64) void { self.w().print("{d}", .{v}) catch {}; }
    fn vec(self: *Emitter, vs: []const f64) void {
        self.w().print("[", .{}) catch {};
        for (vs, 0..) |v, i| { if (i > 0) self.w().print(", ", .{}) catch {}; self.num(v); }
        self.w().print("]", .{}) catch {};
    }
    fn lit(self: *Emitter, l: model.Literal) void {
        switch (l) {
            .scalar => |v| self.num(v),
            .boolean => |b| self.w().print("{s}", .{if (b) "true" else "false"}) catch {},
            .vec => |vs| self.vec(vs),
        }
    }
};

pub fn emit(alloc: std.mem.Allocator, a: *const model.Asset, nt: *const layout.NameTable) ![]u8 {
    var e = Emitter{ .alloc = alloc, .nt = nt, .out = .init(alloc) };
    const w = e.w();
    try w.print("asset {s} version {d};\n", .{ e.ref(a.name), a.version });
    if (a.binary) |b| {
        try w.print("binary {{\n", .{});
        for (b.sections.items) |s| try w.print("  section {s};\n", .{e.ref(s.name)});
        try w.print("}}\n", .{});
    }
    for (a.shaders.items) |s| try w.print("shader {s};\n", .{e.ref(s.name)});
    for (a.meshes.items) |m| try emitMesh(&e, &m);
    for (a.skeletons.items) |sk| try emitSkeleton(&e, &sk);
    for (a.images.items) |im| try emitImage(&e, &im);
    for (a.textures.items) |t| try emitTexture(&e, &t);
    for (a.materials.items) |mt| try emitMaterial(&e, &mt);
    for (a.scenes.items) |sc| {
        try w.print("scene {s} {{\n", .{e.ref(sc.name)});
        for (sc.roots.items) |*n| try emitNode(&e, n, 1);
        try w.print("}}\n", .{});
    }
    for (a.clips.items) |c| try emitClip(&e, &c);
    return e.out.written();
}

fn emitChannel(e: *Emitter, ch: *const model.ChannelDecl, ind: []const u8) !void {
    const w = e.w();
    if (ch.custom) try w.print("{s}attr {s} : {s} @ {s};\n", .{ ind, e.ref(ch.name), ch.ty, e.ref(ch.section) })
    else try w.print("{s}channel {s} : {s} @ {s};\n", .{ ind, ch.name, ch.ty, e.ref(ch.section) });
}

fn emitMesh(e: *Emitter, m: *const model.MeshDecl) !void {
    const w = e.w();
    try w.print("mesh {s} {{\n", .{e.ref(m.name)});
    try w.print("  topology: {s};\n", .{m.topology});
    try w.print("  vertices {d};\n", .{m.vertices});
    if (m.has_bounds) {
        try w.print("  bounds {{ min: ", .{});
        e.vec(m.bounds_min orelse &.{ 0, 0, 0 });
        try w.print("; max: ", .{});
        e.vec(m.bounds_max orelse &.{ 0, 0, 0 });
        try w.print("; }}\n", .{});
    }
    for (m.channels.items) |*ch| try emitChannel(e, ch, "  ");
    for (m.morphs.items) |*mo| {
        try w.print("  morph {s} {{\n", .{e.ref(mo.name)});
        for (mo.channels.items) |*ch| try emitChannel(e, ch, "    ");
        try w.print("  }}\n", .{});
    }
    if (m.idx_ty) |ity| try w.print("  indices {s} @ {s} count {d};\n", .{ ity, e.ref(m.idx_section), m.idx_count });
    for (m.prims.items) |pr| try w.print("  primitive {s} {{ material: {s}; }}\n", .{ e.ref(pr.name), e.ref(pr.material) });
    try w.print("}}\n", .{});
}

fn emitSkeleton(e: *Emitter, sk: *const model.SkeletonDecl) !void {
    const w = e.w();
    try w.print("skeleton {s} {{\n", .{e.ref(sk.name)});
    for (sk.joints.items) |j| {
        try w.print("  joint {s} {{", .{e.ref(j.name)});
        if (j.parent) |par| try w.print(" parent: {s};", .{e.ref(par)}) else try w.print(" parent: none;", .{});
        if (j.has_bind) {
            try w.print(" bind: {{", .{});
            if (j.bind_t) |v| { try w.print(" t: ", .{}); e.vec(v); try w.print(";", .{}); }
            if (j.bind_r) |v| { try w.print(" r: ", .{}); e.vec(v); try w.print(";", .{}); }
            if (j.bind_s) |v| { try w.print(" s: ", .{}); e.vec(v); try w.print(";", .{}); }
            try w.print(" }}", .{});
        }
        try w.print(" }}\n", .{});
    }
    if (sk.ib_section) |sec| try w.print("  inverse_bind @ {s};\n", .{e.ref(sec)});
    try w.print("}}\n", .{});
}

fn emitImage(e: *Emitter, im: *const model.ImageDecl) !void {
    const w = e.w();
    try w.print("image {s} {{\n", .{e.ref(im.name)});
    // 合并形中图像恒为段源（路径源已由打包器内嵌为段）。
    try w.print("  source @ {s};\n", .{e.ref(im.source)});
    try w.print("  format {s};\n", .{im.format});
    if (im.size) |sz| try w.print("  size {d} {d};\n", .{ sz[0], sz[1] });
    try w.print("  color_space {s};\n", .{im.color_space});
    try w.print("}}\n", .{});
}

fn emitTexture(e: *Emitter, t: *const model.TextureDecl) !void {
    const w = e.w();
    try w.print("texture {s} {{\n", .{e.ref(t.name)});
    try w.print("  image: {s};\n", .{e.ref(t.image)});
    if (t.sampler.present) {
        try w.print("  sampler {{", .{});
        if (t.sampler.mag) |v| try w.print(" mag: {s};", .{v});
        if (t.sampler.min) |v| try w.print(" min: {s};", .{v});
        if (t.sampler.mipmap) |v| try w.print(" mipmap: {s};", .{v});
        if (t.sampler.wrap_u) |v| try w.print(" wrap_u: {s};", .{v});
        if (t.sampler.wrap_v) |v| try w.print(" wrap_v: {s};", .{v});
        if (t.sampler.wrap_w) |v| try w.print(" wrap_w: {s};", .{v});
        try w.print(" }}\n", .{});
    }
    try w.print("}}\n", .{});
}

fn emitMaterial(e: *Emitter, mt: *const model.MaterialDecl) !void {
    const w = e.w();
    try w.print("material {s} {{\n", .{e.ref(mt.name)});
    try w.print("  shader: {s};\n", .{e.ref(mt.shader)});
    for (mt.params.items) |pr| {
        try w.print("  param {s} = ", .{pr.name}); // 接口名非资产名，保持字面
        e.lit(pr.lit);
        try w.print(";\n", .{});
    }
    for (mt.texbinds.items) |tb| try w.print("  texture {s}: {s};\n", .{ tb.name, e.ref(tb.texture) });
    for (mt.tex_transforms.items) |tt| {
        try w.print("  tex_transform {s} {{", .{tt.name});
        if (tt.offset) |v| { try w.print(" offset: ", .{}); e.vec(v); try w.print(";", .{}); }
        if (tt.scale) |v| { try w.print(" scale: ", .{}); e.vec(v); try w.print(";", .{}); }
        if (tt.rotation) |v| { try w.print(" rotation: ", .{}); e.num(v); try w.print(";", .{}); }
        try w.print(" }}\n", .{});
    }
    if (mt.alpha != null or mt.cutoff != null or mt.double_sided != null or mt.depth_write != null) {
        try w.print("  state {{", .{});
        if (mt.alpha) |v| try w.print(" alpha: {s};", .{v});
        if (mt.cutoff) |v| { try w.print(" cutoff: ", .{}); e.num(v); try w.print(";", .{}); }
        if (mt.double_sided) |v| try w.print(" double_sided: {s};", .{if (v) "true" else "false"});
        if (mt.depth_write) |v| try w.print(" depth_write: {s};", .{if (v) "true" else "false"});
        try w.print(" }}\n", .{});
    }
    try w.print("}}\n", .{});
}

fn emitNode(e: *Emitter, n: *const model.NodeDecl, depth: usize) !void {
    const w = e.w();
    var indbuf: [32]u8 = undefined;
    const ind = indbuf[0 .. depth * 2];
    @memset(ind, ' ');
    try w.print("{s}node {s} {{\n", .{ ind, e.ref(n.name) });
    if (n.transform) |tr| {
        try w.print("{s}  transform {{", .{ind});
        if (tr.t) |v| { try w.print(" t: ", .{}); e.vec(v); try w.print(";", .{}); }
        if (tr.r) |v| { try w.print(" r: ", .{}); e.vec(v); try w.print(";", .{}); }
        if (tr.s) |v| { try w.print(" s: ", .{}); e.vec(v); try w.print(";", .{}); }
        try w.print(" }}\n", .{});
    }
    if (n.matrix) |v| { try w.print("{s}  matrix: ", .{ind}); e.vec(v); try w.print(";\n", .{}); }
    if (n.mesh) |mn| try w.print("{s}  mesh: {s};\n", .{ ind, e.ref(mn) });
    if (n.material) |mn| try w.print("{s}  material: {s};\n", .{ ind, e.ref(mn) });
    if (n.skin) |sn| try w.print("{s}  skin: {s};\n", .{ ind, e.ref(sn) });
    for (n.children.items) |*c| try emitNode(e, c, depth + 1);
    try w.print("{s}}}\n", .{ind});
}

fn emitClip(e: *Emitter, c: *const model.ClipDecl) !void {
    const w = e.w();
    try w.print("clip {s} {{\n", .{e.ref(c.name)});
    for (c.samplers.items) |s| {
        try w.print("  sampler {s} {{\n", .{e.ref(s.name)});
        try w.print("    input: {s} @ {s} count {d};\n", .{ s.in_ty, e.ref(s.in_section), s.in_count });
        try w.print("    output: {s} @ {s} count {d};\n", .{ s.out_ty, e.ref(s.out_section), s.out_count });
        try w.print("    interpolation: {s};\n", .{s.interpolation});
        try w.print("  }}\n", .{});
    }
    for (c.channels.items) |ch| try w.print("  channel {{ node: {s}; path: {s}; sampler: {s}; }}\n", .{ e.ref(ch.node), ch.path, e.ref(ch.sampler) });
    try w.print("}}\n", .{});
}
