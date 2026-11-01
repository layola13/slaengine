// convert.zig — SAX3D <-> glTF/GLB 双向转换器（Phase 2）。
// 映射规范 = CONVERTER_MAP.md（先表后码）；零静默丢失：一切近似/合成/
// 丢失/不支持逐项进台账（stdout 的 LEDGER 行）或以具名诊断响亮拒绝。
//   convert to-sax3d <in.gltf|in.glb> <outdir> --fixtures-dir <dir>
//   convert to-gltf  <in.sax3d> <in.saxb3d> <outdir> [--iface <Shader>=<file>]...
// to-sax3d 产出后强制过 v1 裁判（内部），过不了以 CvtInternalInvariant
// 拒绝交付；to-gltf 的 SAX3D 输入同样先过裁判。

const std = @import("std");
const lib = @import("sax3d");
const model = lib.model;
const parse = lib.parse;
const checkmod = lib.checkmod;
const ifacemod = lib.ifacemod;
const binio = lib.binio;
const layoutm = lib.layout;

// ---------------- 台账与诊断 ----------------
const Ledger = struct {
    alloc: std.mem.Allocator,
    lines: std.ArrayList([]const u8) = .empty,
    n_loss: usize = 0,
    n_approx: usize = 0,
    n_synth: usize = 0,
    fn add(self: *Ledger, kind: []const u8, comptime fmt: []const u8, args: anytype) void {
        const msg = std.fmt.allocPrint(self.alloc, fmt, args) catch return;
        self.lines.append(self.alloc, std.fmt.allocPrint(self.alloc, "LEDGER {s} {s}", .{ kind, msg }) catch return) catch {};
        if (std.mem.eql(u8, kind, "LOSS")) self.n_loss += 1;
        if (std.mem.eql(u8, kind, "APPROX")) self.n_approx += 1;
        if (std.mem.eql(u8, kind, "SYNTH")) self.n_synth += 1;
    }
    fn print(self: *Ledger, io: std.Io) void {
        for (self.lines.items) |l| {
            std.Io.File.stdout().writeStreamingAll(io, l) catch {};
            std.Io.File.stdout().writeStreamingAll(io, "\n") catch {};
        }
        const tail = std.fmt.allocPrint(self.alloc, "LEDGER SUMMARY loss={d} approx={d} synth={d} total={d}\n", .{ self.n_loss, self.n_approx, self.n_synth, self.lines.items.len }) catch return;
        std.Io.File.stdout().writeStreamingAll(io, tail) catch {};
    }
};

const Ctx = struct {
    alloc: std.mem.Allocator,
    io: std.Io,
    diags: model.Diags,
    ledger: Ledger,
    fn fail(self: *Ctx, code: []const u8, comptime fmt: []const u8, args: anytype) error{ConvertFailed} {
        self.diags.add(code, fmt, args);
        return error.ConvertFailed;
    }
    fn readFile(self: *Ctx, path: []const u8) error{ConvertFailed}![]u8 {
        return std.Io.Dir.cwd().readFileAlloc(self.io, path, self.alloc, .limited(1 << 30)) catch |e|
            self.fail("CvtBadInput", "cannot read '{s}': {s}", .{ path, @errorName(e) });
    }
};

// ---------------- JSON 助手 ----------------
const J = std.json.Value;
fn jo(v: J) ?std.json.ObjectMap { return if (v == .object) v.object else null; }
fn ja(v: J) ?[]const J { return if (v == .array) v.array.items else null; }
fn jg(v: J, key: []const u8) ?J { const o = jo(v) orelse return null; return o.get(key); }
fn js(v: J) ?[]const u8 { return if (v == .string) v.string else null; }
fn ji(v: J) ?i64 {
    return switch (v) { .integer => |x| x, .float => |f| @intFromFloat(f), else => null };
}
fn jf(v: J) ?f64 {
    return switch (v) { .float => |f| f, .integer => |x| @floatFromInt(x), else => null };
}
fn jAt(v: J, key: []const u8) ?J { return jg(v, key); }
fn arrLen(v: ?J) usize { const x = v orelse return 0; return if (ja(x)) |a| a.len else 0; }
fn arrAt(v: ?J, i: usize) ?J { const x = v orelse return null; const a = ja(x) orelse return null; return if (i < a.len) a[i] else null; }

// ---------------- glTF 装载 ----------------
const AccessorInfo = struct { comp: i64, ty: []const u8, count: usize, normalized: bool, elem_size: usize };

const Gltf = struct {
    root: J,
    buffers: std.ArrayList([]const u8) = .empty, // 已解出的 buffer 字节（按 index）
    dir: []const u8,

    fn compSize(c: i64) usize {
        return switch (c) { 5120, 5121 => 1, 5122, 5123 => 2, 5125, 5126 => 4, else => 0 };
    }
    fn typeComps(t: []const u8) usize {
        if (std.mem.eql(u8, t, "SCALAR")) return 1;
        if (std.mem.eql(u8, t, "VEC2")) return 2;
        if (std.mem.eql(u8, t, "VEC3")) return 3;
        if (std.mem.eql(u8, t, "VEC4")) return 4;
        if (std.mem.eql(u8, t, "MAT2")) return 4;
        if (std.mem.eql(u8, t, "MAT3")) return 9;
        if (std.mem.eql(u8, t, "MAT4")) return 16;
        return 0;
    }
    fn accessorInfo(self: *Gltf, idx: usize) ?AccessorInfo {
        const acc = arrAt(jg(self.root, "accessors"), idx) orelse return null;
        const comp = ji(jg(acc, "componentType") orelse return null) orelse return null;
        const ty = js(jg(acc, "type") orelse return null) orelse return null;
        const count = ji(jg(acc, "count") orelse return null) orelse return null;
        const cs = compSize(comp);
        const tc = typeComps(ty);
        if (cs == 0 or tc == 0) return null;
        return .{ .comp = comp, .ty = ty, .count = @intCast(count), .normalized = if (jg(acc, "normalized")) |n| n == .bool and n.bool else false, .elem_size = cs * tc };
    }
    // 紧密提取 accessor 字节（解交错）；sparse 响亮拒绝。
    fn accessorBytes(self: *Gltf, ctx: *Ctx, idx: usize) ![]u8 {
        const acc = arrAt(jg(self.root, "accessors"), idx) orelse return ctx.fail("CvtBadInput", "accessor {d} missing", .{idx});
        if (jg(acc, "sparse") != null) return ctx.fail("CvtSparseAccessor", "accessor {d} is sparse (unsupported per map)", .{idx});
        const info = self.accessorInfo(idx) orelse return ctx.fail("CvtBadInput", "accessor {d} malformed", .{idx});
        const bv_idx = ji(jg(acc, "bufferView") orelse return ctx.fail("CvtBadInput", "accessor {d} has no bufferView", .{idx})) orelse return ctx.fail("CvtBadInput", "accessor {d} bufferView not an int", .{idx});
        const bv = arrAt(jg(self.root, "bufferViews"), @intCast(bv_idx)) orelse return ctx.fail("CvtBadInput", "bufferView {d} missing", .{bv_idx});
        const buf_idx: usize = @intCast(ji(jg(bv, "buffer") orelse .{ .integer = 0 }) orelse 0);
        if (buf_idx >= self.buffers.items.len) return ctx.fail("CvtBadInput", "buffer {d} not loaded", .{buf_idx});
        const src = self.buffers.items[buf_idx];
        const bv_off: usize = @intCast(ji(jg(bv, "byteOffset") orelse .{ .integer = 0 }) orelse 0);
        const bv_len: usize = @intCast(ji(jg(bv, "byteLength") orelse return ctx.fail("CvtBadInput", "bufferView {d} lacks byteLength", .{bv_idx})) orelse 0);
        const acc_off: usize = @intCast(ji(jg(acc, "byteOffset") orelse .{ .integer = 0 }) orelse 0);
        const stride: usize = if (jg(bv, "byteStride")) |s| @intCast(ji(s) orelse @as(i64, @intCast(info.elem_size))) else info.elem_size;
        const out = ctx.alloc.alloc(u8, info.elem_size * info.count) catch return error.OutOfMemory;
        var i: usize = 0;
        while (i < info.count) : (i += 1) {
            const so = bv_off + acc_off + i * stride;
            if (so + info.elem_size > bv_off + bv_len or so + info.elem_size > src.len)
                return ctx.fail("CvtBadInput", "accessor {d} element {d} overruns its bufferView", .{ idx, i });
            @memcpy(out[i * info.elem_size ..][0..info.elem_size], src[so..][0..info.elem_size]);
        }
        return out;
    }
};

fn loadGltf(ctx: *Ctx, path: []const u8) !Gltf {
    const raw = try ctx.readFile(path);
    var g = Gltf{ .root = undefined, .dir = std.fs.path.dirname(path) orelse "." };
    var json_bytes: []const u8 = raw;
    var glb_bin: ?[]const u8 = null;
    if (raw.len >= 12 and std.mem.eql(u8, raw[0..4], "glTF")) {
        const total = std.mem.readInt(u32, raw[8..12], .little);
        if (total > raw.len) return ctx.fail("CvtBadInput", "GLB length field {d} exceeds file {d}", .{ total, raw.len });
        var off: usize = 12;
        while (off + 8 <= raw.len) {
            const clen = std.mem.readInt(u32, raw[off..][0..4], .little);
            const ctype = raw[off + 4 ..][0..4];
            if (off + 8 + clen > raw.len) return ctx.fail("CvtBadInput", "GLB chunk overruns file", .{});
            const cdata = raw[off + 8 ..][0..@intCast(clen)];
            if (std.mem.eql(u8, ctype, "JSON")) json_bytes = cdata;
            if (std.mem.eql(u8, ctype, "BIN\x00")) glb_bin = cdata;
            off += 8 + clen;
        }
    }
    const parsed = std.json.parseFromSlice(J, ctx.alloc, json_bytes, .{}) catch |e|
        return ctx.fail("CvtBadInput", "JSON parse failed: {s}", .{@errorName(e)});
    g.root = parsed.value;
    // buffers 逐个解出
    const nbuf = arrLen(jg(g.root, "buffers"));
    var bi: usize = 0;
    while (bi < nbuf) : (bi += 1) {
        const bdesc = arrAt(jg(g.root, "buffers"), bi).?;
        if (jg(bdesc, "uri")) |u| {
            const uri = js(u) orelse return ctx.fail("CvtBadInput", "buffer {d} uri not a string", .{bi});
            if (std.mem.startsWith(u8, uri, "data:")) {
                const comma = std.mem.indexOfScalar(u8, uri, ',') orelse return ctx.fail("CvtBadInput", "buffer {d} data URI malformed", .{bi});
                const enc = uri[comma + 1 ..];
                const dec = std.base64.standard.Decoder;
                const sz = dec.calcSizeForSlice(enc) catch return ctx.fail("CvtBadInput", "buffer {d} base64 size bad", .{bi});
                const buf = ctx.alloc.alloc(u8, sz) catch return error.OutOfMemory;
                dec.decode(buf, enc) catch return ctx.fail("CvtBadInput", "buffer {d} base64 decode failed", .{bi});
                try g.buffers.append(ctx.alloc, buf);
            } else {
                const full = std.fmt.allocPrint(ctx.alloc, "{s}/{s}", .{ g.dir, uri }) catch return error.OutOfMemory;
                try g.buffers.append(ctx.alloc, try ctx.readFile(full));
            }
        } else if (glb_bin) |bb| {
            try g.buffers.append(ctx.alloc, bb);
        } else return ctx.fail("CvtBadInput", "buffer {d} has neither uri nor GLB BIN chunk", .{bi});
    }
    // 扩展门
    if (jg(g.root, "extensionsRequired")) |er| {
        if (ja(er)) |a| { for (a) |e| {
            const en = js(e) orelse continue;
            if (!std.mem.eql(u8, en, "KHR_texture_transform"))
                return ctx.fail("CvtUnsupportedExtension", "extensionsRequired contains '{s}' (unsupported per map)", .{en});
        } }
    }
    if (jg(g.root, "extensionsUsed")) |eu| {
        if (ja(eu)) |a| { for (a) |e| {
            const en = js(e) orelse continue;
            if (!std.mem.eql(u8, en, "KHR_texture_transform"))
                ctx.ledger.add("LOSS", "extensionsUsed '{s}' not understood; conversion is PARTIAL for that extension's semantics", .{en});
        } }
    }
    return g;
}

// ---------------- 名字池（索引→名主键化） ----------------
const KEYWORDS = [_][]const u8{ "asset", "binary", "mesh", "skeleton", "image", "texture", "shader", "material", "scene", "clip", "node", "joint", "sampler", "channel", "attr", "morph", "primitive", "section", "inverse_bind", "vertices", "transform", "matrix", "skin", "state", "topology", "parent", "bind", "source", "format", "size", "color_space", "param", "indices", "input", "output", "interpolation", "path", "version", "bounds" };

const NamePool = struct {
    used: std.StringHashMap(void),
    fn init(alloc: std.mem.Allocator) NamePool { return .{ .used = .init(alloc) }; }
    fn sanitize(alloc: std.mem.Allocator, raw: []const u8) []const u8 {
        var out: std.ArrayList(u8) = .empty;
        for (raw) |c| {
            const okc = (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_' or c == '-';
            out.append(alloc, if (okc) c else '_') catch {};
        }
        if (out.items.len == 0) out.appendSlice(alloc, "unnamed") catch {};
        if (out.items[0] >= '0' and out.items[0] <= '9' or out.items[0] == '-') out.insert(alloc, 0, 'n') catch {};
        return out.items;
    }
    // claim: 原名合法唯一 → 原样；否则合成/改名（进台账）。
    fn claim(self: *NamePool, ctx: *Ctx, raw: ?[]const u8, kind: []const u8, idx: usize) []const u8 {
        const fallback = std.fmt.allocPrint(ctx.alloc, "{s}_{d}", .{ kind, idx }) catch unreachable;
        const wanted = if (raw) |r| sanitize(ctx.alloc, r) else fallback;
        var candidate = wanted;
        var is_kw = false;
        for (KEYWORDS) |k| { if (std.mem.eql(u8, candidate, k)) is_kw = true; }
        if (is_kw) candidate = std.fmt.allocPrint(ctx.alloc, "{s}_", .{candidate}) catch unreachable;
        if (self.used.contains(candidate)) {
            var n: usize = 1;
            while (true) : (n += 1) {
                const c2 = std.fmt.allocPrint(ctx.alloc, "{s}_{d}", .{ candidate, idx + n }) catch unreachable;
                if (!self.used.contains(c2)) { candidate = c2; break; }
            }
        }
        self.used.put(candidate, {}) catch {};
        if (raw == null) {
            ctx.ledger.add("SYNTH", "name for {s}[{d}] absent in source; synthesised '{s}'", .{ kind, idx, candidate });
        } else if (!std.mem.eql(u8, candidate, raw.?)) {
            ctx.ledger.add("SYNTH", "name for {s}[{d}] sanitised/deduped '{s}' -> '{s}'", .{ kind, idx, raw.?, candidate });
        }
        return candidate;
    }
};

// ---------------- 小工具 ----------------
fn readF32(bytes: []const u8, i: usize) f32 { return @bitCast(std.mem.readInt(u32, bytes[i * 4 ..][0..4], .little)); }
fn writeF32(buf: *std.ArrayList(u8), alloc: std.mem.Allocator, v: f32) void {
    var b: [4]u8 = undefined;
    std.mem.writeInt(u32, &b, @bitCast(v), .little);
    buf.appendSlice(alloc, &b) catch {};
}
fn fmtNum(alloc: std.mem.Allocator, v: f64) []const u8 { return std.fmt.allocPrint(alloc, "{d}", .{v}) catch "?"; }

// ---------------- 文本构建助手 ----------------
fn put(alloc: std.mem.Allocator, buf: *std.ArrayList(u8), comptime fmt: []const u8, args: anytype) void {
    const s = std.fmt.allocPrint(alloc, fmt, args) catch return;
    buf.appendSlice(alloc, s) catch {};
}
fn vecStr(alloc: std.mem.Allocator, vs: []const f64) []const u8 {
    var out: std.ArrayList(u8) = .empty;
    put(alloc, &out, "[", .{});
    for (vs, 0..) |v, i| { if (i > 0) put(alloc, &out, ", ", .{}); put(alloc, &out, "{d}", .{v}); }
    put(alloc, &out, "]", .{});
    return out.items;
}
// 从 JSON 数组取 f64 数组（arena 分配）
fn jF64Arr(ctx: *Ctx, v: ?J, n: usize) ?[]f64 {
    const a = ja(v orelse return null) orelse return null;
    if (a.len != n) return null;
    const out = ctx.alloc.alloc(f64, n) catch return null;
    for (a, 0..) |e, i| { out[i] = jf(e) orelse return null; }
    return out;
}

// 派生法线：positions f32x3；indices 可空（非索引=逐面精确；索引=面积加权累积）
fn deriveNormals(ctx: *Ctx, pos: []const u8, idx: ?[]const u8, idx_is_u32: bool) ![]u8 {
    const n = pos.len / 12;
    const acc = ctx.alloc.alloc(f32, n * 3) catch return error.OutOfMemory;
    @memset(acc, 0);
    const triCount = if (idx) |ib| ib.len / (if (idx_is_u32) @as(usize, 4) else 2) / 3 else n / 3;
    var t: usize = 0;
    while (t < triCount) : (t += 1) {
        var vi: [3]usize = undefined;
        for (0..3) |k| {
            vi[k] = if (idx) |ib| (if (idx_is_u32) std.mem.readInt(u32, ib[(t * 3 + k) * 4 ..][0..4], .little) else std.mem.readInt(u16, ib[(t * 3 + k) * 2 ..][0..2], .little)) else t * 3 + k;
        }
        const a: [3]f32 = .{ readF32(pos, vi[0] * 3), readF32(pos, vi[0] * 3 + 1), readF32(pos, vi[0] * 3 + 2) };
        const b: [3]f32 = .{ readF32(pos, vi[1] * 3), readF32(pos, vi[1] * 3 + 1), readF32(pos, vi[1] * 3 + 2) };
        const c: [3]f32 = .{ readF32(pos, vi[2] * 3), readF32(pos, vi[2] * 3 + 1), readF32(pos, vi[2] * 3 + 2) };
        const u: [3]f32 = .{ b[0] - a[0], b[1] - a[1], b[2] - a[2] };
        const v: [3]f32 = .{ c[0] - a[0], c[1] - a[1], c[2] - a[2] };
        const cr: [3]f32 = .{ u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0] };
        for (vi) |ix| { for (0..3) |k| acc[ix * 3 + k] += cr[k]; }
    }
    var out: std.ArrayList(u8) = .empty;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var x = acc[i * 3]; var y = acc[i * 3 + 1]; var z = acc[i * 3 + 2];
        const l = @sqrt(x * x + y * y + z * z);
        if (l > 0) { x /= l; y /= l; z /= l; } else { x = 0; y = 0; z = 1; }
        writeF32(&out, ctx.alloc, x); writeF32(&out, ctx.alloc, y); writeF32(&out, ctx.alloc, z);
    }
    return out.items;
}

// ---------------- to-sax3d ----------------
const SectionOut = struct { name: []const u8, bytes: []const u8 };
const Conv1 = struct {
    ctx: *Ctx,
    g: *Gltf,
    pool_mesh: NamePool, pool_mat: NamePool, pool_node: NamePool, pool_tex: NamePool,
    pool_img: NamePool, pool_skin: NamePool, pool_scene: NamePool, pool_clip: NamePool,
    pool_section: NamePool,
    sections: std.ArrayList(SectionOut) = .empty,
    payload_by_section: std.StringHashMap([]const u8),
    node_names: std.ArrayList([]const u8) = .empty,
    node_parent: std.AutoHashMap(usize, usize),
    mesh_names: std.ArrayList(std.ArrayList([]const u8)) = .empty, // glTF mesh -> SAX3D mesh 名组
    mesh_axes: std.ArrayList(std.ArrayList([2]bool)) = .empty,     // 每组 (skin, uv)
    mat_variants: std.StringHashMap([]const u8),                  // "mat|skin|uv|tex" -> SAX3D 材质名
    shaders_used: std.StringHashMap(void),
    skin_names: std.ArrayList([]const u8) = .empty,
    tex_names: std.ArrayList([]const u8) = .empty,
    img_names: std.ArrayList([]const u8) = .empty,
    txt_img: std.ArrayList(u8) = .empty,
    txt_tex: std.ArrayList(u8) = .empty,
    txt_mesh: std.ArrayList(u8) = .empty,
    txt_skel: std.ArrayList(u8) = .empty,
    txt_mat: std.ArrayList(u8) = .empty,
    txt_scene: std.ArrayList(u8) = .empty,
    txt_clip: std.ArrayList(u8) = .empty,

    acc_section: std.AutoHashMap(usize, []const u8) = undefined,
    fn addSection(self: *Conv1, raw_name: []const u8, bytes: []const u8) []const u8 {
        const nm = self.pool_section.claim(self.ctx, raw_name, "section", self.sections.items.len);
        self.sections.append(self.ctx.alloc, .{ .name = nm, .bytes = bytes }) catch {};
        self.payload_by_section.put(nm, bytes) catch {};
        return nm;
    }
    // 按源 accessor 去重：同一 accessor 多处引用（如多采样器共用时间轴、
    // 多网格共用 accessor）只落一段——同源即同数据，语义精确。
    fn accSection(self: *Conv1, acc_idx: usize, raw_name: []const u8, bytes: []const u8) []const u8 {
        if (self.acc_section.get(acc_idx)) |nm| return nm;
        const nm = self.addSection(raw_name, bytes);
        self.acc_section.put(acc_idx, nm) catch {};
        return nm;
    }
};

fn shaderNameFor(alloc: std.mem.Allocator, skin: bool, tex: bool, uv: bool) []const u8 {
    return std.fmt.allocPrint(alloc, "StdPbr{s}{s}{s}", .{
        if (skin) "Skinned" else "", if (tex) "" else "Nt", if (uv) "" else "Nu",
    }) catch unreachable;
}
fn fixtureFileFor(alloc: std.mem.Allocator, shader: []const u8) []const u8 {
    var out: std.ArrayList(u8) = .empty;
    for (shader, 0..) |c, i| {
        if (c >= 'A' and c <= 'Z') {
            if (i > 0) out.append(alloc, '_') catch {};
            out.append(alloc, c + 32) catch {};
        } else out.append(alloc, c) catch {};
    }
    return out.items;
}

fn convChannelBytes(c: *Conv1, acc_idx: usize, want: []const u8) !struct { bytes: []const u8, elem: []const u8 } {
    const ctx = c.ctx;
    const info = c.g.accessorInfo(acc_idx) orelse return ctx.fail("CvtBadInput", "accessor {d} malformed", .{acc_idx});
    const raw = try c.g.accessorBytes(ctx, acc_idx);
    // joints u8x4 -> u16x4 拓宽
    if (std.mem.eql(u8, want, "joints") and info.comp == 5121) {
        var out: std.ArrayList(u8) = .empty;
        var i: usize = 0;
        while (i < raw.len) : (i += 1) {
            var b: [2]u8 = undefined;
            std.mem.writeInt(u16, &b, raw[i], .little);
            out.appendSlice(ctx.alloc, &b) catch {};
        }
        ctx.ledger.add("APPROX", "JOINTS_0 u8 widened to u16 (values preserved, bytes change) in accessor {d}", .{acc_idx});
        return .{ .bytes = out.items, .elem = "u16x4" };
    }
    // weights 归一化整数 -> f32
    if (std.mem.eql(u8, want, "weights") and (info.comp == 5121 or info.comp == 5123) and info.normalized) {
        var out: std.ArrayList(u8) = .empty;
        const div: f32 = if (info.comp == 5121) 255.0 else 65535.0;
        var i: usize = 0;
        while (i < raw.len) : (i += if (info.comp == 5121) @as(usize, 1) else 2) {
            const v: f32 = if (info.comp == 5121) @as(f32, @floatFromInt(raw[i])) / div
                else @as(f32, @floatFromInt(std.mem.readInt(u16, raw[i..][0..2], .little))) / div;
            writeF32(&out, ctx.alloc, v);
        }
        ctx.ledger.add("APPROX", "WEIGHTS_0 normalized integers converted to f32 in accessor {d}", .{acc_idx});
        return .{ .bytes = out.items, .elem = "f32x4" };
    }
    return .{ .bytes = raw, .elem = "" };
}

fn elemNameFor(ctx: *Ctx, info: AccessorInfo, acc_idx: usize) ![]const u8 {
    if (info.comp == 5126 and std.mem.eql(u8, info.ty, "SCALAR")) return "f32";
    if (info.comp == 5126 and std.mem.eql(u8, info.ty, "VEC2")) return "f32x2";
    if (info.comp == 5126 and std.mem.eql(u8, info.ty, "VEC3")) return "f32x3";
    if (info.comp == 5126 and std.mem.eql(u8, info.ty, "VEC4")) return "f32x4";
    if (info.comp == 5123 and std.mem.eql(u8, info.ty, "VEC4")) return "u16x4";
    if (info.comp == 5121 and std.mem.eql(u8, info.ty, "VEC4")) return "u8x4";
    if (info.comp == 5125 and std.mem.eql(u8, info.ty, "SCALAR")) return "u32";
    if (info.comp == 5123 and std.mem.eql(u8, info.ty, "SCALAR")) return "u16";
    return ctx.fail("CvtUnsupportedElemType", "accessor {d}: componentType {d} type {s} has no SAX3D element type", .{ acc_idx, info.comp, info.ty });
}

// ---------------- to-sax3d 主体 ----------------
const ImgKind = enum { section, path };
const ImgDecl = struct { name: []const u8, kind: ImgKind, ref: []const u8, format: []const u8, cs: []const u8 };
const TexInfo = struct { name: []const u8, image: []const u8, mag: []const u8, min: []const u8, mip: []const u8, wu: []const u8, wv: []const u8 };

fn wrapName(v: ?J) []const u8 {
    const x = ji(v orelse .{ .integer = 10497 }) orelse 10497;
    return switch (x) { 33071 => "clamp", 33648 => "mirror", else => "repeat" };
}
fn filtName(v: ?J, def: []const u8) []const u8 {
    const x = ji(v orelse return def) orelse return def;
    return if (x == 9728) "nearest" else "linear";
}

fn emitMatVariant(c: *Conv1, mat_idx: i64, vname: []const u8, shader: []const u8, tex_names: []const []const u8) !void {
    const ctx = c.ctx;
    var t: std.ArrayList(u8) = .empty;
    put(ctx.alloc, &t, "material {s} {{\n  shader: {s};\n", .{ vname, shader });
    var base = [_]f64{ 1, 1, 1, 1 };
    var rough: f64 = 1.0;
    var metal: f64 = 1.0;
    var alpha: []const u8 = "opaque";
    var cutoff: ?f64 = null;
    var dbl = false;
    var texbind: ?[]const u8 = null;
    var tt: ?J = null;
    if (mat_idx >= 0) {
        const m = arrAt(jg(c.g.root, "materials"), @intCast(mat_idx)) orelse return ctx.fail("CvtBadInput", "material {d} missing", .{mat_idx});
        if (jg(m, "pbrMetallicRoughness")) |pbr| {
            if (jF64Arr(ctx, jg(pbr, "baseColorFactor"), 4)) |a| base = a[0..4].*;
            if (jg(pbr, "roughnessFactor")) |v| rough = jf(v) orelse rough;
            if (jg(pbr, "metallicFactor")) |v| metal = jf(v) orelse metal;
            if (jg(pbr, "baseColorTexture")) |ti| {
                const tcoord = ji(jg(ti, "texCoord") orelse .{ .integer = 0 }) orelse 0;
                if (tcoord != 0) return ctx.fail("CvtUnsupportedTextureSlot", "baseColorTexture texCoord {d} != 0 (no per-binding channel select in SAX3D v1)", .{tcoord});
                const tidx = ji(jg(ti, "index") orelse return ctx.fail("CvtBadInput", "baseColorTexture lacks index", .{})) orelse return ctx.fail("CvtBadInput", "baseColorTexture index not int", .{});
                if (tidx < 0 or tidx >= @as(i64, @intCast(tex_names.len))) return ctx.fail("CvtBadInput", "baseColorTexture index {d} out of range", .{tidx});
                texbind = tex_names[@intCast(tidx)];
                if (jg(ti, "extensions")) |ext| { if (jg(ext, "KHR_texture_transform")) |ktt| tt = ktt; }
            }
            for ([_][]const u8{ "metallicRoughnessTexture", "normalTexture", "occlusionTexture", "emissiveTexture" }) |slot| {
                if (jg(pbr, slot) != null or jg(m, slot) != null)
                    return ctx.fail("CvtUnsupportedTextureSlot", "material slot '{s}' has no StdPbr interface slot (map §2)", .{slot});
            }
        }
        if (jg(m, "emissiveFactor")) |ef| {
            if (jF64Arr(ctx, ef, 3)) |a| { if (a[0] != 0 or a[1] != 0 or a[2] != 0)
                return ctx.fail("CvtUnsupportedParam", "emissiveFactor [{d}, {d}, {d}] nonzero: StdPbr has no emissive param (map §2)", .{ a[0], a[1], a[2] }); }
        }
        if (js(jg(m, "alphaMode") orelse .{ .string = "OPAQUE" })) |am| {
            if (std.mem.eql(u8, am, "BLEND")) alpha = "blend";
            if (std.mem.eql(u8, am, "MASK")) { alpha = "mask"; if (jg(m, "alphaCutoff")) |co| cutoff = jf(co); }
        }
        if (jg(m, "doubleSided")) |ds| { if (ds == .bool and ds.bool) dbl = true; }
    }
    put(ctx.alloc, &t, "  param base_color = {s};\n", .{vecStr(ctx.alloc, &base)});
    put(ctx.alloc, &t, "  param roughness = {d};\n", .{rough});
    put(ctx.alloc, &t, "  param metallic = {d};\n", .{metal});
    if (texbind) |tb| put(ctx.alloc, &t, "  texture base_color_map: {s};\n", .{tb});
    if (tt) |ktt| {
        put(ctx.alloc, &t, "  tex_transform base_color_map {{", .{});
        if (jF64Arr(ctx, jg(ktt, "offset"), 2)) |a| put(ctx.alloc, &t, " offset: {s};", .{vecStr(ctx.alloc, a)});
        if (jF64Arr(ctx, jg(ktt, "scale"), 2)) |a| put(ctx.alloc, &t, " scale: {s};", .{vecStr(ctx.alloc, a)});
        if (jg(ktt, "rotation")) |r| put(ctx.alloc, &t, " rotation: {d};", .{jf(r) orelse 0});
        put(ctx.alloc, &t, " }}\n", .{});
        ctx.ledger.add("APPROX", "KHR_texture_transform on material '{s}' mapped to tex_transform (map §2)", .{vname});
    }
    if (!std.mem.eql(u8, alpha, "opaque") or cutoff != null or dbl) {
        put(ctx.alloc, &t, "  state {{ alpha: {s};", .{alpha});
        if (cutoff) |co| put(ctx.alloc, &t, " cutoff: {d};", .{co});
        if (dbl) put(ctx.alloc, &t, " double_sided: true;", .{});
        put(ctx.alloc, &t, " }}\n", .{});
    }
    put(ctx.alloc, &t, "}}\n", .{});
    c.txt_mat.appendSlice(ctx.alloc, t.items) catch {};
}

// Conv1 的材质文本收集（后向声明占位，实际定义随主体）
fn toSax3d(ctx: *Ctx, in_path: []const u8, outdir: []const u8, fixtures_dir: []const u8) !void {
    var g = try loadGltf(ctx, in_path);
    var c = Conv1{
        .ctx = ctx, .g = &g,
        .pool_mesh = NamePool.init(ctx.alloc), .pool_mat = NamePool.init(ctx.alloc),
        .pool_node = NamePool.init(ctx.alloc), .pool_tex = NamePool.init(ctx.alloc),
        .pool_img = NamePool.init(ctx.alloc), .pool_skin = NamePool.init(ctx.alloc),
        .pool_scene = NamePool.init(ctx.alloc), .pool_clip = NamePool.init(ctx.alloc),
        .pool_section = NamePool.init(ctx.alloc),
        .payload_by_section = .init(ctx.alloc), .node_parent = .init(ctx.alloc),
        .mat_variants = .init(ctx.alloc), .shaders_used = .init(ctx.alloc),
        .acc_section = .init(ctx.alloc),
    };
    const root = g.root;
    // ---- 节点名与父图（先行） ----
    const n_nodes = arrLen(jg(root, "nodes"));
    {
        var i: usize = 0;
        while (i < n_nodes) : (i += 1) {
            const nd = arrAt(jg(root, "nodes"), i).?;
            try c.node_names.append(ctx.alloc, c.pool_node.claim(ctx, js(jg(nd, "name") orelse .{ .null = {} }), "node", i));
        }
        // 父图：遍历全部 scene 树
        const nsc = arrLen(jg(root, "scenes"));
        var si: usize = 0;
        while (si < nsc) : (si += 1) {
            const sc = arrAt(jg(root, "scenes"), si).?;
            for (ja(jg(sc, "nodes") orelse .{ .null = {} }) orelse &.{}) |rv| {
                if (ji(rv)) |ri| try buildParents(ctx, &c, @intCast(ri));
            }
        }
    }
    // ---- 图像角色（色空间推断依据） ----
    var img_role: std.AutoHashMap(usize, []const u8) = .init(ctx.alloc);
    {
        const nm = arrLen(jg(root, "materials"));
        var mi: usize = 0;
        while (mi < nm) : (mi += 1) {
            const m = arrAt(jg(root, "materials"), mi).?;
            const slots = [_]struct { pbr: bool, key: []const u8, cs: []const u8 }{
                .{ .pbr = true, .key = "baseColorTexture", .cs = "srgb" },
                .{ .pbr = false, .key = "emissiveTexture", .cs = "srgb" },
                .{ .pbr = false, .key = "normalTexture", .cs = "linear" },
                .{ .pbr = false, .key = "occlusionTexture", .cs = "linear" },
                .{ .pbr = true, .key = "metallicRoughnessTexture", .cs = "linear" },
            };
            for (slots) |s| {
                const holder = if (s.pbr) jg(m, "pbrMetallicRoughness") else m;
                if (holder) |h| { if (jg(h, s.key)) |ti| {
                    if (ji(jg(ti, "index") orelse .{ .null = {} })) |tidx| {
                        const tex = arrAt(jg(root, "textures"), @intCast(tidx)) orelse continue;
                        if (ji(jg(tex, "source") orelse .{ .null = {} })) |sidx| try img_role.put(@intCast(sidx), s.cs);
                    }
                } }
            }
        }
    }
    // ---- 图像声明 ----
    var img_decls: std.ArrayList(ImgDecl) = .empty;
    {
        const ni = arrLen(jg(root, "images"));
        var i: usize = 0;
        while (i < ni) : (i += 1) {
            const im = arrAt(jg(root, "images"), i).?;
            const name = c.pool_img.claim(ctx, js(jg(im, "name") orelse .{ .null = {} }), "image", i);
            var format: []const u8 = "png";
            var kind: ImgKind = .section;
            var ref: []const u8 = "";
            if (jg(im, "bufferView")) |bvv| {
                const bvi = ji(bvv) orelse return ctx.fail("CvtBadInput", "image {d} bufferView not int", .{i});
                const bv = arrAt(jg(root, "bufferViews"), @intCast(bvi)) orelse return ctx.fail("CvtBadInput", "image {d} bufferView {d} missing", .{ i, bvi });
                const buf_idx: usize = @intCast(ji(jg(bv, "buffer") orelse .{ .integer = 0 }) orelse 0);
                const bo: usize = @intCast(ji(jg(bv, "byteOffset") orelse .{ .integer = 0 }) orelse 0);
                const bl: usize = @intCast(ji(jg(bv, "byteLength") orelse return ctx.fail("CvtBadInput", "image bufferView lacks byteLength", .{})) orelse 0);
                if (buf_idx >= g.buffers.items.len or bo + bl > g.buffers.items[buf_idx].len)
                    return ctx.fail("CvtBadInput", "image {d} bufferView overruns buffer", .{i});
                ref = c.addSection(std.fmt.allocPrint(ctx.alloc, "{s}_data", .{name}) catch unreachable, g.buffers.items[buf_idx][bo..][0..bl]);
                const mime = js(jg(im, "mimeType") orelse .{ .null = {} }) orelse return ctx.fail("CvtBadInput", "image {d} (bufferView) lacks mimeType", .{i});
                format = mimeToFormat(ctx, mime) orelse return ctx.fail("CvtBadInput", "image {d} mimeType '{s}' unsupported", .{ i, mime });
            } else if (jg(im, "uri")) |u| {
                const uri = js(u) orelse return ctx.fail("CvtBadInput", "image {d} uri not string", .{i});
                if (std.mem.startsWith(u8, uri, "data:")) {
                    const comma = std.mem.indexOfScalar(u8, uri, ',') orelse return ctx.fail("CvtBadInput", "image {d} data URI malformed", .{i});
                    const dec = std.base64.standard.Decoder;
                    const sz = dec.calcSizeForSlice(uri[comma + 1 ..]) catch return ctx.fail("CvtBadInput", "image {d} base64 bad", .{i});
                    const buf = ctx.alloc.alloc(u8, sz) catch return error.OutOfMemory;
                    dec.decode(buf, uri[comma + 1 ..]) catch return ctx.fail("CvtBadInput", "image {d} base64 decode failed", .{i});
                    ref = c.addSection(std.fmt.allocPrint(ctx.alloc, "{s}_data", .{name}) catch unreachable, buf);
                    const mime = js(jg(im, "mimeType") orelse .{ .string = "image/png" }) orelse "image/png";
                    format = mimeToFormat(ctx, mime) orelse "png";
                } else {
                    kind = .path;
                    ref = uri;
                    format = extToFormat(uri) orelse return ctx.fail("CvtBadInput", "image {d} uri '{s}': cannot determine format from extension", .{ i, uri });
                }
            } else return ctx.fail("CvtBadInput", "image {d} has neither bufferView nor uri", .{i});
            const cs = img_role.get(i) orelse blk: {
                ctx.ledger.add("APPROX", "image '{s}': referenced by no material slot role; color_space inferred srgb (map §3)", .{name});
                break :blk "srgb";
            };
            try img_decls.append(ctx.alloc, .{ .name = name, .kind = kind, .ref = ref, .format = format, .cs = cs });
            try c.img_names.append(ctx.alloc, name);
        }
    }
    // ---- 纹理 ----
    var tex_infos: std.ArrayList(TexInfo) = .empty;
    {
        const nt = arrLen(jg(root, "textures"));
        var i: usize = 0;
        while (i < nt) : (i += 1) {
            const tx = arrAt(jg(root, "textures"), i).?;
            const name = c.pool_tex.claim(ctx, js(jg(tx, "name") orelse .{ .null = {} }), "texture", i);
            const sidx = ji(jg(tx, "source") orelse return ctx.fail("CvtBadInput", "texture {d} lacks source", .{i})) orelse return ctx.fail("CvtBadInput", "texture {d} source not int", .{i});
            if (sidx < 0 or sidx >= @as(i64, @intCast(c.img_names.items.len))) return ctx.fail("CvtBadInput", "texture {d} source {d} out of range", .{ i, sidx });
            var ti = TexInfo{ .name = name, .image = c.img_names.items[@intCast(sidx)], .mag = "linear", .min = "linear", .mip = "linear", .wu = "repeat", .wv = "repeat" };
            if (jg(tx, "sampler")) |sv| {
                const sidx2 = ji(sv) orelse return ctx.fail("CvtBadInput", "texture {d} sampler not int", .{i});
                const smp = arrAt(jg(root, "samplers"), @intCast(sidx2)) orelse return ctx.fail("CvtBadInput", "sampler {d} missing", .{sidx2});
                ti.mag = filtName(jg(smp, "magFilter"), "linear");
                const minf = ji(jg(smp, "minFilter") orelse .{ .integer = 9987 }) orelse 9987;
                switch (minf) {
                    9728 => { ti.min = "nearest"; ti.mip = "none"; },
                    9729 => { ti.min = "linear"; ti.mip = "none"; },
                    9984 => { ti.min = "nearest"; ti.mip = "nearest"; },
                    9985 => { ti.min = "nearest"; ti.mip = "linear"; },
                    9986 => { ti.min = "linear"; ti.mip = "nearest"; },
                    9987 => { ti.min = "linear"; ti.mip = "linear"; },
                    else => return ctx.fail("CvtBadInput", "sampler minFilter {d} unknown", .{minf}),
                }
                ti.wu = wrapName(jg(smp, "wrapS"));
                ti.wv = wrapName(jg(smp, "wrapT"));
            } else {
                ctx.ledger.add("APPROX", "texture '{s}': no sampler in glTF; explicit sampler state = glTF defaults (linear/linear-mipmap-linear/repeat)", .{name});
            }
            try tex_infos.append(ctx.alloc, ti);
            try c.tex_names.append(ctx.alloc, name);
        }
    }
    for (img_decls.items) |d| {
        put(ctx.alloc, &c.txt_img, "image {s} {{\n", .{d.name});
        if (d.kind == .section) put(ctx.alloc, &c.txt_img, "  source @ {s};\n", .{d.ref})
        else put(ctx.alloc, &c.txt_img, "  source \"{s}\";\n", .{d.ref});
        put(ctx.alloc, &c.txt_img, "  format {s};\n  color_space {s};\n}}\n", .{ d.format, d.cs });
    }
    for (tex_infos.items) |ti| {
        put(ctx.alloc, &c.txt_tex, "texture {s} {{\n  image: {s};\n  sampler {{ mag: {s}; min: {s}; mipmap: {s}; wrap_u: {s}; wrap_v: {s}; }}\n}}\n", .{ ti.name, ti.image, ti.mag, ti.min, ti.mip, ti.wu, ti.wv });
    }
    try convMeshes(ctx, &c);
    try convSkins(ctx, &c);
    try convScenes(ctx, &c);
    try convClips(ctx, &c);
    // ---- 组装文本 ----
    const stem = std.fs.path.basename(in_path);
    const stem_noext = if (std.mem.lastIndexOfScalar(u8, stem, '.')) |di| stem[0..di] else stem;
    var asset_pool = NamePool.init(ctx.alloc);
    const asset_name = asset_pool.claim(ctx, stem_noext, "asset", 0);
    var text: std.ArrayList(u8) = .empty;
    put(ctx.alloc, &text, "asset {s} version 1;\n\nbinary \"{s}.saxb3d\" {{\n", .{ asset_name, asset_name });
    for (c.sections.items) |s| put(ctx.alloc, &text, "    section {s} {d};\n", .{ s.name, s.bytes.len });
    put(ctx.alloc, &text, "}}\n\n", .{});
    var sh_it = c.shaders_used.keyIterator();
    var shader_names: std.ArrayList([]const u8) = .empty;
    while (sh_it.next()) |k| try shader_names.append(ctx.alloc, k.*);
    std.mem.sort([]const u8, shader_names.items, {}, struct {
        fn lt(_: void, a: []const u8, b: []const u8) bool { return std.mem.order(u8, a, b) == .lt; }
    }.lt);
    for (shader_names.items) |sn| put(ctx.alloc, &text, "shader {s}: slasl \"{s}.slasl\";\n", .{ sn, fixtureFileFor(ctx.alloc, sn) });
    if (shader_names.items.len > 0) put(ctx.alloc, &text, "\n", .{});
    put(ctx.alloc, &text, "{s}{s}{s}{s}{s}{s}", .{ c.txt_mesh.items, c.txt_skel.items, c.txt_img.items, c.txt_tex.items, c.txt_mat.items, c.txt_scene.items });
    text.appendSlice(ctx.alloc, c.txt_clip.items) catch {};
    // ---- 内部裁判（产出必须过自家校验器） ----
    {
        var ifaces: std.StringHashMap(ifacemod.Iface) = .init(ctx.alloc);
        var rdiags = model.Diags.init(ctx.alloc);
        for (shader_names.items) |sn| {
            const fp = std.fmt.allocPrint(ctx.alloc, "{s}/{s}.iface.txt", .{ fixtures_dir, fixtureFileFor(ctx.alloc, sn) }) catch unreachable;
            const fsrc = ctx.readFile(fp) catch return ctx.fail("CvtBadInput", "fixture for shader '{s}' not found at '{s}'", .{ sn, fp });
            ifaces.put(sn, ifacemod.parseIface(ctx.alloc, fsrc, &rdiags, sn)) catch {};
        }
        var ast = parse.parse(ctx.alloc, text.items, .authoring, &.{}, &rdiags) catch {
            rdiags.printAll();
            return ctx.fail("CvtInternalInvariant", "converted asset text does not parse", .{});
        };
        _ = checkmod.check(ctx.alloc, &ast, &ifaces, &rdiags);
        if (rdiags.count() > 0) {
            rdiags.printAll();
            return ctx.fail("CvtInternalInvariant", "converted asset FAILED the SAX3D referee ({d} diagnostics) — refusing to deliver", .{rdiags.count()});
        }
    }
    // ---- 写出 ----
    std.Io.Dir.cwd().createDirPath(ctx.io, outdir) catch {};
    const payload_dir = std.fmt.allocPrint(ctx.alloc, "{s}/payload", .{outdir}) catch unreachable;
    std.Io.Dir.cwd().createDirPath(ctx.io, payload_dir) catch {};
    for (c.sections.items) |s| {
        const p = std.fmt.allocPrint(ctx.alloc, "{s}/{s}.bin", .{ payload_dir, s.name }) catch unreachable;
        std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = p, .data = s.bytes }) catch |e|
            return ctx.fail("CvtBadInput", "cannot write payload '{s}': {s}", .{ p, @errorName(e) });
    }
    const text_path = std.fmt.allocPrint(ctx.alloc, "{s}/{s}.sax3d", .{ outdir, asset_name }) catch unreachable;
    std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = text_path, .data = text.items }) catch |e|
        return ctx.fail("CvtBadInput", "cannot write '{s}': {s}", .{ text_path, @errorName(e) });
    std.debug.print("WROTE {s} (+{d} payload sections)\n", .{ text_path, c.sections.items.len });
}

fn buildParents(ctx: *Ctx, c: *Conv1, ni: usize) !void {
    const nd = arrAt(jg(c.g.root, "nodes"), ni) orelse return;
    if (jg(nd, "children")) |ch| {
        if (ja(ch)) |a| { for (a) |cv| {
            if (ji(cv)) |ci| {
                try c.node_parent.put(@intCast(ci), ni);
                try buildParents(ctx, c, @intCast(ci));
            }
        } }
    }
}

fn mimeToFormat(ctx: *Ctx, mime: []const u8) ?[]const u8 {
    _ = ctx;
    if (std.mem.eql(u8, mime, "image/png")) return "png";
    if (std.mem.eql(u8, mime, "image/jpeg")) return "jpeg";
    if (std.mem.eql(u8, mime, "image/ktx2")) return "ktx2";
    return null;
}
fn extToFormat(uri: []const u8) ?[]const u8 {
    if (std.mem.endsWith(u8, uri, ".png")) return "png";
    if (std.mem.endsWith(u8, uri, ".jpg") or std.mem.endsWith(u8, uri, ".jpeg")) return "jpeg";
    if (std.mem.endsWith(u8, uri, ".ktx2")) return "ktx2";
    return null;
}

// ---------------- to-sax3d: 网格 ----------------
const CANON_ATTRS = [_][]const u8{ "POSITION", "NORMAL", "TANGENT", "TEXCOORD_0", "TEXCOORD_1", "TEXCOORD_2", "TEXCOORD_3", "COLOR_0", "JOINTS_0", "WEIGHTS_0" };
fn isCanonAttr(k: []const u8) bool { for (CANON_ATTRS) |c| { if (std.mem.eql(u8, k, c)) return true; } return false; }
fn matHasBaseTex(g: *Gltf, mat_idx: i64) bool {
    if (mat_idx < 0) return false;
    const m = arrAt(jg(g.root, "materials"), @intCast(mat_idx)) orelse return false;
    const pbr = jg(m, "pbrMetallicRoughness") orelse return false;
    return jg(pbr, "baseColorTexture") != null;
}

fn convMeshes(ctx: *Ctx, c: *Conv1) !void {
    const root = c.g.root;
    const nm = arrLen(jg(root, "meshes"));
    var mi: usize = 0;
    while (mi < nm) : (mi += 1) {
        const mesh = arrAt(jg(root, "meshes"), mi).?;
        if (jg(mesh, "weights")) |wv| {
            if (ja(wv)) |a| {
                for (a) |e| { if ((jf(e) orelse 0) != 0) return ctx.fail("CvtUnsupportedParam", "mesh {d}: nonzero default morph weights have no SAX3D counterpart", .{mi}); }
                if (a.len > 0) ctx.ledger.add("APPROX", "mesh {d}: all-zero default morph weights omitted (equivalent)", .{mi});
            }
        }
        const prims = ja(jg(mesh, "primitives") orelse .{ .null = {} }) orelse return ctx.fail("CvtBadInput", "mesh {d} lacks primitives array", .{mi});
        // 分组签名
        var sigs: std.ArrayList([]const u8) = .empty;
        var groups: std.ArrayList(std.ArrayList(usize)) = .empty;
        for (prims, 0..) |p, pi| {
            var sig: std.ArrayList(u8) = .empty;
            const attrs = jo(jg(p, "attributes") orelse .{ .null = {} }) orelse return ctx.fail("CvtBadInput", "mesh {d} prim {d} lacks attributes", .{ mi, pi });
            var keys: std.ArrayList([]const u8) = .empty;
            var kit = attrs.iterator();
            while (kit.next()) |e| try keys.append(ctx.alloc, e.key_ptr.*);
            std.mem.sort([]const u8, keys.items, {}, struct { fn lt(_: void, a: []const u8, b: []const u8) bool { return std.mem.order(u8, a, b) == .lt; } }.lt);
            for (keys.items) |k| put(ctx.alloc, &sig, "{s}={d};", .{ k, ji(attrs.get(k).?) orelse -1 });
            put(ctx.alloc, &sig, "IDX={d};MODE={d};", .{ ji(jg(p, "indices") orelse .{ .integer = -1 }) orelse -1, ji(jg(p, "mode") orelse .{ .integer = 4 }) orelse 4 });
            if (jg(p, "targets")) |tg| {
                if (ja(tg)) |ta| { for (ta) |td| {
                    if (jo(td)) |to| {
                        var tk: std.ArrayList([]const u8) = .empty;
                        var tit = to.iterator();
                        while (tit.next()) |e| try tk.append(ctx.alloc, e.key_ptr.*);
                        std.mem.sort([]const u8, tk.items, {}, struct { fn lt(_: void, a: []const u8, b: []const u8) bool { return std.mem.order(u8, a, b) == .lt; } }.lt);
                        for (tk.items) |k| put(ctx.alloc, &sig, "T:{s}={d};", .{ k, ji(to.get(k).?) orelse -1 });
                    }
                } }
            }
            var placed = false;
            for (sigs.items, 0..) |s, gi| { if (std.mem.eql(u8, s, sig.items)) { try groups.items[gi].append(ctx.alloc, pi); placed = true; } }
            if (!placed) {
                try sigs.append(ctx.alloc, sig.items);
                var ng: std.ArrayList(usize) = .empty;
                try ng.append(ctx.alloc, pi);
                try groups.append(ctx.alloc, ng);
            }
        }
        var group_names: std.ArrayList([]const u8) = .empty;
        var group_axes: std.ArrayList([2]bool) = .empty;
        for (groups.items) |grp| {
            const rep = prims[grp.items[0]];
            const attrs = jo(jg(rep, "attributes") orelse .{ .null = {} }).?;
            const mesh_name = c.pool_mesh.claim(ctx, js(jg(mesh, "name") orelse .{ .null = {} }), "mesh", mi);
            const pos_acc = ji(attrs.get("POSITION") orelse return ctx.fail("CvtBadInput", "mesh {d}: primitive without POSITION", .{mi})) orelse return ctx.fail("CvtBadInput", "POSITION accessor not int", .{});
            const pos_info = c.g.accessorInfo(@intCast(pos_acc)) orelse return ctx.fail("CvtBadInput", "POSITION accessor malformed", .{});
            if (pos_info.comp != 5126 or !std.mem.eql(u8, pos_info.ty, "VEC3")) return ctx.fail("CvtUnsupportedElemType", "mesh {d}: POSITION must be f32 VEC3", .{mi});
            const vcount = pos_info.count;
            const pos_bytes = try c.g.accessorBytes(ctx, @intCast(pos_acc));
            // indices（先行：法线派生要用）
            var idx_bytes: ?[]const u8 = null;
            var idx_acc_idx: ?usize = null;
            var idx_elem: []const u8 = "";
            var idx_count: usize = 0;
            var idx_is32 = false;
            if (jg(rep, "indices")) |iv| {
                const ia = ji(iv) orelse return ctx.fail("CvtBadInput", "indices not int", .{});
                idx_acc_idx = @intCast(ia);
                const iinfo = c.g.accessorInfo(@intCast(ia)) orelse return ctx.fail("CvtBadInput", "indices accessor malformed", .{});
                idx_count = iinfo.count;
                if (iinfo.comp == 5123) { idx_bytes = try c.g.accessorBytes(ctx, @intCast(ia)); idx_elem = "u16"; }
                else if (iinfo.comp == 5125) { idx_bytes = try c.g.accessorBytes(ctx, @intCast(ia)); idx_elem = "u32"; idx_is32 = true; }
                else if (iinfo.comp == 5121) {
                    const rawb = try c.g.accessorBytes(ctx, @intCast(ia));
                    var out: std.ArrayList(u8) = .empty;
                    for (rawb) |b| { var bb: [2]u8 = undefined; std.mem.writeInt(u16, &bb, b, .little); out.appendSlice(ctx.alloc, &bb) catch {}; }
                    idx_bytes = out.items; idx_elem = "u16";
                    ctx.ledger.add("APPROX", "mesh '{s}': u8 indices widened to u16 (values preserved)", .{mesh_name});
                } else return ctx.fail("CvtUnsupportedElemType", "mesh {d}: indices componentType {d} unsupported", .{ mi, iinfo.comp });
            }
            var body: std.ArrayList(u8) = .empty;
            const mode = ji(jg(rep, "mode") orelse .{ .integer = 4 }) orelse 4;
            const topo: []const u8 = switch (mode) { 0 => "points", 1 => "lines", 3 => "line-strip", 4 => "triangles", 5 => "triangle-strip", 6 => "triangle-fan",
                else => return ctx.fail("CvtUnsupportedTopology", "mesh {d}: primitive mode {d} (line-loop etc.) unsupported", .{ mi, mode }) };
            put(ctx.alloc, &body, "mesh {s} {{\n  topology: {s};\n  vertices {d};\n", .{ mesh_name, topo, vcount });
            var has_uv = false;
            var has_skin = false;
            // 规范通道（固定序）
            const role_map = [_]struct { key: []const u8, role: []const u8, elem: []const u8 }{
                .{ .key = "POSITION", .role = "position", .elem = "f32x3" },
                .{ .key = "NORMAL", .role = "normal", .elem = "f32x3" },
                .{ .key = "TANGENT", .role = "tangent", .elem = "f32x4" },
                .{ .key = "TEXCOORD_0", .role = "uv0", .elem = "f32x2" },
                .{ .key = "TEXCOORD_1", .role = "uv1", .elem = "f32x2" },
                .{ .key = "TEXCOORD_2", .role = "uv2", .elem = "f32x2" },
                .{ .key = "TEXCOORD_3", .role = "uv3", .elem = "f32x2" },
            };
            for (role_map) |rm| {
                if (attrs.get(rm.key)) |av| {
                    const ai = ji(av) orelse return ctx.fail("CvtBadInput", "{s} accessor not int", .{rm.key});
                    const ainfo = c.g.accessorInfo(@intCast(ai)) orelse return ctx.fail("CvtBadInput", "{s} accessor malformed", .{rm.key});
                    if (ainfo.count != vcount) return ctx.fail("CvtBadInput", "mesh '{s}': {s} count {d} != vertex count {d}", .{ mesh_name, rm.key, ainfo.count, vcount });
                    const bytes = if (std.mem.eql(u8, rm.key, "POSITION")) pos_bytes else try c.g.accessorBytes(ctx, @intCast(ai));
                    const sec = c.accSection(@intCast(ai), std.fmt.allocPrint(ctx.alloc, "{s}_{s}", .{ mesh_name, rm.role }) catch unreachable, bytes);
                    put(ctx.alloc, &body, "  channel {s} : {s} @ {s};\n", .{ rm.role, rm.elem, sec });
                    if (std.mem.startsWith(u8, rm.role, "uv0")) has_uv = true;
                }
            }
            // NORMAL 缺失 → 派生
            if (attrs.get("NORMAL") == null) {
                const derived = try deriveNormals(ctx, pos_bytes, idx_bytes, idx_is32);
                const sec = c.addSection(std.fmt.allocPrint(ctx.alloc, "{s}_normal_derived", .{mesh_name}) catch unreachable, derived);
                put(ctx.alloc, &body, "  channel normal : f32x3 @ {s};\n", .{sec});
                ctx.ledger.add("APPROX", "mesh '{s}': NORMAL absent; normals derived ({s}) into section '{s}'", .{ mesh_name, if (idx_bytes == null) "flat per-face, exact for non-indexed geometry" else "area-weighted accumulation", sec });
            }
            // COLOR_0
            if (attrs.get("COLOR_0")) |av| {
                const ai = ji(av) orelse return ctx.fail("CvtBadInput", "COLOR_0 not int", .{});
                const ainfo = c.g.accessorInfo(@intCast(ai)) orelse return ctx.fail("CvtBadInput", "COLOR_0 malformed", .{});
                if (ainfo.count != vcount) return ctx.fail("CvtBadInput", "mesh '{s}': COLOR_0 count mismatch", .{mesh_name});
                const en = try elemNameFor(ctx, ainfo, @intCast(ai));
                if (!std.mem.eql(u8, en, "f32x4") and !std.mem.eql(u8, en, "u8x4"))
                    return ctx.fail("CvtUnsupportedElemType", "mesh '{s}': COLOR_0 element {s} unsupported (need f32x4/u8x4)", .{ mesh_name, en });
                const bytes = try c.g.accessorBytes(ctx, @intCast(ai));
                const sec = c.accSection(@intCast(ai), std.fmt.allocPrint(ctx.alloc, "{s}_color0", .{mesh_name}) catch unreachable, bytes);
                put(ctx.alloc, &body, "  channel color0 : {s} @ {s};\n", .{ en, sec });
            }
            // JOINTS_0 / WEIGHTS_0
            for ([_]struct { key: []const u8, role: []const u8, want: []const u8, elem: []const u8 }{
                .{ .key = "JOINTS_0", .role = "joints0", .want = "joints", .elem = "u16x4" },
                .{ .key = "WEIGHTS_0", .role = "weights0", .want = "weights", .elem = "f32x4" },
            }) |jm| {
                if (attrs.get(jm.key)) |av| {
                    const ai = ji(av) orelse return ctx.fail("CvtBadInput", "{s} not int", .{jm.key});
                    const ainfo = c.g.accessorInfo(@intCast(ai)) orelse return ctx.fail("CvtBadInput", "{s} malformed", .{jm.key});
                    if (ainfo.count != vcount) return ctx.fail("CvtBadInput", "mesh '{s}': {s} count mismatch", .{ mesh_name, jm.key });
                    const conv = try convChannelBytes(c, @intCast(ai), jm.want);
                    if (!std.mem.eql(u8, conv.elem, jm.elem) and conv.elem.len > 0) return ctx.fail("CvtUnsupportedElemType", "mesh '{s}': {s} element {s} unsupported", .{ mesh_name, jm.key, conv.elem });
                    if (conv.elem.len == 0) {
                        const en = try elemNameFor(ctx, ainfo, @intCast(ai));
                        if (!std.mem.eql(u8, en, jm.elem)) return ctx.fail("CvtUnsupportedElemType", "mesh '{s}': {s} element {s} unsupported (need {s})", .{ mesh_name, jm.key, en, jm.elem });
                    }
                    const sec = c.accSection(@intCast(ai), std.fmt.allocPrint(ctx.alloc, "{s}_{s}", .{ mesh_name, jm.role }) catch unreachable, conv.bytes);
                    put(ctx.alloc, &body, "  channel {s} : {s} @ {s};\n", .{ jm.role, jm.elem, sec });
                    if (std.mem.eql(u8, jm.role, "joints0")) has_skin = true;
                }
            }
            // 自定义属性
            {
                var kit = attrs.iterator();
                while (kit.next()) |e| {
                    const k = e.key_ptr.*;
                    if (isCanonAttr(k)) continue;
                    if (std.mem.startsWith(u8, k, "TEXCOORD_")) return ctx.fail("CvtUnsupportedElemType", "mesh '{s}': {s} exceeds uv0..uv3", .{ mesh_name, k });
                    if (!std.mem.startsWith(u8, k, "_")) return ctx.fail("CvtBadInput", "mesh '{s}': attribute '{s}' is neither standard nor _-prefixed custom", .{ mesh_name, k });
                    const ai = ji(e.value_ptr.*) orelse return ctx.fail("CvtBadInput", "custom attr not int", .{});
                    const ainfo = c.g.accessorInfo(@intCast(ai)) orelse return ctx.fail("CvtBadInput", "custom attr malformed", .{});
                    const en = try elemNameFor(ctx, ainfo, @intCast(ai));
                    const aname = k[1..];
                    const bytes = try c.g.accessorBytes(ctx, @intCast(ai));
                    const sec = c.accSection(@intCast(ai), std.fmt.allocPrint(ctx.alloc, "{s}_attr_{s}", .{ mesh_name, aname }) catch unreachable, bytes);
                    put(ctx.alloc, &body, "  attr {s} : {s} @ {s};\n", .{ aname, en, sec });
                }
            }
            // morph 目标
            if (jg(rep, "targets")) |tg| {
                if (ja(tg)) |ta| {
                    var mpool = NamePool.init(ctx.alloc);
                    const tnames = if (jg(mesh, "extras")) |ex| jg(ex, "targetNames") else null;
                    for (ta, 0..) |td, ti2| {
                        const raw_name: ?[]const u8 = if (tnames) |tn| (if (arrAt(tn, ti2)) |nv| js(nv) else null) else null;
                        const mname = mpool.claim(ctx, raw_name, "morph", ti2);
                        put(ctx.alloc, &body, "  morph {s} {{\n", .{mname});
                        if (jo(td)) |to| {
                            var tit = to.iterator();
                            while (tit.next()) |e| {
                                const role: []const u8 = if (std.mem.eql(u8, e.key_ptr.*, "POSITION")) "position"
                                    else if (std.mem.eql(u8, e.key_ptr.*, "NORMAL")) "normal"
                                    else if (std.mem.eql(u8, e.key_ptr.*, "TANGENT")) "tangent"
                                    else return ctx.fail("CvtUnsupportedElemType", "mesh '{s}': morph target attribute '{s}' unsupported", .{ mesh_name, e.key_ptr.* });
                                const ai = ji(e.value_ptr.*) orelse return ctx.fail("CvtBadInput", "morph attr not int", .{});
                                const ainfo = c.g.accessorInfo(@intCast(ai)) orelse return ctx.fail("CvtBadInput", "morph attr malformed", .{});
                                if (ainfo.count != vcount) return ctx.fail("CvtBadInput", "mesh '{s}': morph count mismatch", .{mesh_name});
                                const en = try elemNameFor(ctx, ainfo, @intCast(ai));
                                const want_elem: []const u8 = if (std.mem.eql(u8, role, "tangent")) "f32x4" else "f32x3";
                                if (!std.mem.eql(u8, en, want_elem)) return ctx.fail("CvtUnsupportedElemType", "mesh '{s}': morph {s} element {s} unsupported", .{ mesh_name, role, en });
                                const bytes = try c.g.accessorBytes(ctx, @intCast(ai));
                                const sec = c.accSection(@intCast(ai), std.fmt.allocPrint(ctx.alloc, "{s}_morph_{s}_{s}", .{ mesh_name, mname, role }) catch unreachable, bytes);
                                put(ctx.alloc, &body, "    channel {s} : {s} @ {s};\n", .{ role, en, sec });
                            }
                        }
                        put(ctx.alloc, &body, "  }}\n", .{});
                    }
                }
            }
            // indices 行
            if (idx_bytes) |ib| {
                const sec = if (idx_acc_idx) |ia2| c.accSection(ia2, std.fmt.allocPrint(ctx.alloc, "{s}_idx", .{mesh_name}) catch unreachable, ib) else c.addSection(std.fmt.allocPrint(ctx.alloc, "{s}_idx", .{mesh_name}) catch unreachable, ib);
                put(ctx.alloc, &body, "  indices {s} @ {s} count {d};\n", .{ idx_elem, sec, idx_count });
            }
            // primitives
            {
                var ppool = NamePool.init(ctx.alloc);
                for (grp.items, 0..) |gpi, gj| {
                    _ = gj;
                    const p = prims[gpi];
                    const pname = ppool.claim(ctx, null, "primitive", gpi);
                    const mat_idx: i64 = ji(jg(p, "material") orelse .{ .integer = -1 }) orelse -1;
                    const tex = matHasBaseTex(c.g, mat_idx);
                    const shader = shaderNameFor(ctx.alloc, has_skin, tex, has_uv);
                    try c.shaders_used.put(shader, {});
                    const vkey = std.fmt.allocPrint(ctx.alloc, "{d}|{d}{d}{d}", .{ mat_idx, @intFromBool(has_skin), @intFromBool(tex), @intFromBool(has_uv) }) catch unreachable;
                    const vname = if (c.mat_variants.get(vkey)) |vn| vn else blk: {
                        const rawm: ?[]const u8 = if (mat_idx >= 0) js(jg(arrAt(jg(root, "materials"), @intCast(mat_idx)).?, "name") orelse .{ .null = {} }) else null;
                        const vn = c.pool_mat.claim(ctx, rawm orelse "DefaultMaterial", "material", if (mat_idx >= 0) @intCast(mat_idx) else 0);
                        ctx.ledger.add("SYNTH", "material '{s}' bound to shader '{s}' (glTF has no shader concept; map §2 standard-PBR binding)", .{ vn, shader });
                        try emitMatVariant(c, mat_idx, vn, shader, c.tex_names.items);
                        try c.mat_variants.put(vkey, vn);
                        break :blk vn;
                    };
                    put(ctx.alloc, &body, "  primitive {s} {{ material: {s}; }}\n", .{ pname, vname });
                }
            }
            put(ctx.alloc, &body, "}}\n", .{});
            c.txt_mesh.appendSlice(ctx.alloc, body.items) catch {};
            try group_names.append(ctx.alloc, mesh_name);
            try group_axes.append(ctx.alloc, .{ has_skin, has_uv });
        }
        if (groups.items.len > 1)
            ctx.ledger.add("APPROX", "mesh {d}: primitives have differing attribute/index sets; split into {d} SAX3D meshes (map §1)", .{ mi, groups.items.len });
        try c.mesh_names.append(ctx.alloc, group_names);
        try c.mesh_axes.append(ctx.alloc, group_axes);
    }
}

// ---------------- to-sax3d: 骨骼 ----------------
fn convSkins(ctx: *Ctx, c: *Conv1) !void {
    const root = c.g.root;
    const nsk = arrLen(jg(root, "skins"));
    var si: usize = 0;
    while (si < nsk) : (si += 1) {
        const sk = arrAt(jg(root, "skins"), si).?;
        const name = c.pool_skin.claim(ctx, js(jg(sk, "name") orelse .{ .null = {} }), "skeleton", si);
        const joints = ja(jg(sk, "joints") orelse .{ .null = {} }) orelse return ctx.fail("CvtBadInput", "skin {d} lacks joints", .{si});
        var joint_set: std.AutoHashMap(usize, void) = .init(ctx.alloc);
        for (joints) |jv| { if (ji(jv)) |jn| try joint_set.put(@intCast(jn), {}); }
        var ib_bytes: []const u8 = undefined;
        if (jg(sk, "inverseBindMatrices")) |iv| {
            const ia = ji(iv) orelse return ctx.fail("CvtBadInput", "inverseBindMatrices not int", .{});
            ib_bytes = try c.g.accessorBytes(ctx, @intCast(ia));
        } else {
            const buf = ctx.alloc.alloc(u8, joints.len * 64) catch return error.OutOfMemory;
            @memset(buf, 0);
            for (0..joints.len) |j2| { for ([_]usize{ 0, 20, 40, 60 }) |off| { var fb: [4]u8 = undefined; std.mem.writeInt(u32, &fb, @bitCast(@as(f32, 1.0)), .little); @memcpy(buf[j2 * 64 + off ..][0..4], &fb); } }
            ib_bytes = buf;
            ctx.ledger.add("SYNTH", "skeleton '{s}': inverseBindMatrices absent; identity matrices synthesised (= glTF default semantics)", .{name});
        }
        if (jg(sk, "skeleton")) |skv| {
            ctx.ledger.add("LOSS", "skeleton '{s}': skin.skeleton root hint (node {d}) dropped — optimisation hint only, no semantics", .{ name, ji(skv) orelse -1 });
        }
        const sec = if (jg(sk, "inverseBindMatrices")) |iv| c.accSection(@intCast(ji(iv) orelse 0), std.fmt.allocPrint(ctx.alloc, "{s}_ib", .{name}) catch unreachable, ib_bytes) else c.addSection(std.fmt.allocPrint(ctx.alloc, "{s}_ib", .{name}) catch unreachable, ib_bytes);
        put(ctx.alloc, &c.txt_skel, "skeleton {s} {{\n", .{name});
        for (joints) |jv| {
            const jn = ji(jv) orelse return ctx.fail("CvtBadInput", "joint not int", .{});
            const jname = c.node_names.items[@intCast(jn)];
            var parent_name: ?[]const u8 = null;
            var cur = c.node_parent.get(@intCast(jn));
            while (cur) |cu| {
                if (joint_set.contains(cu)) { parent_name = c.node_names.items[cu]; break; }
                cur = c.node_parent.get(cu);
            }
            if (parent_name) |pn| put(ctx.alloc, &c.txt_skel, "  joint {s} {{ parent: {s}; }}\n", .{ jname, pn })
            else put(ctx.alloc, &c.txt_skel, "  joint {s} {{ parent: none; }}\n", .{jname});
        }
        put(ctx.alloc, &c.txt_skel, "  inverse_bind @ {s};\n}}\n", .{sec});
        try c.skin_names.append(ctx.alloc, name);
    }
}

// ---------------- to-sax3d: 场景 ----------------
fn emitNodeC(ctx: *Ctx, c: *Conv1, buf: *std.ArrayList(u8), ni: usize, depth: usize) !void {
    const nd = arrAt(jg(c.g.root, "nodes"), ni) orelse return ctx.fail("CvtBadInput", "node {d} missing", .{ni});
    const name = c.node_names.items[ni];
    if (jg(nd, "camera") != null) return ctx.fail("CvtUnsupportedNodeFeature", "node '{s}' carries a camera (F-7 core-only scope)", .{name});
    if (jg(nd, "weights")) |wv| {
        if (ja(wv)) |a| { for (a) |e| { if ((jf(e) orelse 0) != 0) return ctx.fail("CvtUnsupportedNodeFeature", "node '{s}' has nonzero morph weights (no SAX3D counterpart)", .{name}); } }
    }
    var ind: std.ArrayList(u8) = .empty;
    for (0..depth * 2) |_| ind.append(ctx.alloc, ' ') catch {};
    put(ctx.alloc, buf, "{s}node {s} {{\n", .{ ind.items, name });
    if (jg(nd, "matrix")) |mv| {
        if (jF64Arr(ctx, mv, 16)) |a| put(ctx.alloc, buf, "{s}  matrix: {s};\n", .{ ind.items, vecStr(ctx.alloc, a) });
    } else if (jg(nd, "translation") != null or jg(nd, "rotation") != null or jg(nd, "scale") != null) {
        put(ctx.alloc, buf, "{s}  transform {{", .{ind.items});
        if (jF64Arr(ctx, jg(nd, "translation"), 3)) |a| put(ctx.alloc, buf, " t: {s};", .{vecStr(ctx.alloc, a)});
        if (jF64Arr(ctx, jg(nd, "rotation"), 4)) |a| put(ctx.alloc, buf, " r: {s};", .{vecStr(ctx.alloc, a)});
        if (jF64Arr(ctx, jg(nd, "scale"), 3)) |a| put(ctx.alloc, buf, " s: {s};", .{vecStr(ctx.alloc, a)});
        put(ctx.alloc, buf, " }}\n", .{});
    }
    if (jg(nd, "mesh")) |mv| {
        const mix = ji(mv) orelse return ctx.fail("CvtBadInput", "node mesh not int", .{});
        const groups = c.mesh_names.items[@intCast(mix)];
        put(ctx.alloc, buf, "{s}  mesh: {s};\n", .{ ind.items, groups.items[0] });
        if (jg(nd, "skin")) |sv| {
            const skx = ji(sv) orelse return ctx.fail("CvtBadInput", "node skin not int", .{});
            put(ctx.alloc, buf, "{s}  skin: {s};\n", .{ ind.items, c.skin_names.items[@intCast(skx)] });
        }
        // 多组拆分：额外组以合成子节点补挂
        if (groups.items.len > 1) {
            for (groups.items[1..], 1..) |gn, k| {
                const pn = c.pool_node.claim(ctx, std.fmt.allocPrint(ctx.alloc, "{s}__part{d}", .{ name, k }) catch unreachable, "node", ni);
                put(ctx.alloc, buf, "{s}  node {s} {{ mesh: {s}; }}\n", .{ ind.items, pn, gn });
                ctx.ledger.add("APPROX", "node '{s}': split-mesh group '{s}' bound via synthesised child node '{s}'", .{ name, gn, pn });
            }
        }
    }
    if (jg(nd, "children")) |ch| {
        if (ja(ch)) |a| { for (a) |cv| { if (ji(cv)) |ci| try emitNodeC(ctx, c, buf, @intCast(ci), depth + 1); } }
    }
    put(ctx.alloc, buf, "{s}}}\n", .{ind.items});
}

fn convScenes(ctx: *Ctx, c: *Conv1) !void {
    const nsc = arrLen(jg(c.g.root, "scenes"));
    var si: usize = 0;
    while (si < nsc) : (si += 1) {
        const sc = arrAt(jg(c.g.root, "scenes"), si).?;
        const name = c.pool_scene.claim(ctx, js(jg(sc, "name") orelse .{ .null = {} }), "scene", si);
        put(ctx.alloc, &c.txt_scene, "scene {s} {{\n", .{name});
        if (jg(sc, "nodes")) |ns| {
            if (ja(ns)) |a| { for (a) |nv| { if (ji(nv)) |ni| try emitNodeC(ctx, c, &c.txt_scene, @intCast(ni), 1); } }
        }
        put(ctx.alloc, &c.txt_scene, "}}\n", .{});
    }
}

// ---------------- to-sax3d: 动画 ----------------
fn convClips(ctx: *Ctx, c: *Conv1) !void {
    const root = c.g.root;
    const na = arrLen(jg(root, "animations"));
    var ai: usize = 0;
    while (ai < na) : (ai += 1) {
        const an = arrAt(jg(root, "animations"), ai).?;
        const name = c.pool_clip.claim(ctx, js(jg(an, "name") orelse .{ .null = {} }), "clip", ai);
        put(ctx.alloc, &c.txt_clip, "clip {s} {{\n", .{name});
        ctx.ledger.add("SYNTH", "clip '{s}': sampler names synthesised S<a>_<s> (glTF samplers are unnamed)", .{name});
        const samplers = ja(jg(an, "samplers") orelse .{ .null = {} }) orelse &.{};
        var sampler_names: std.ArrayList([]const u8) = .empty;
        for (samplers, 0..) |sm, sj| {
            const sname = std.fmt.allocPrint(ctx.alloc, "S{d}_{d}", .{ ai, sj }) catch unreachable;
            try sampler_names.append(ctx.alloc, sname);
            const in_acc = ji(jg(sm, "input") orelse return ctx.fail("CvtBadInput", "anim sampler lacks input", .{})) orelse return ctx.fail("CvtBadInput", "input not int", .{});
            const out_acc = ji(jg(sm, "output") orelse return ctx.fail("CvtBadInput", "anim sampler lacks output", .{})) orelse return ctx.fail("CvtBadInput", "output not int", .{});
            const in_info = c.g.accessorInfo(@intCast(in_acc)) orelse return ctx.fail("CvtBadInput", "anim input malformed", .{});
            const out_info = c.g.accessorInfo(@intCast(out_acc)) orelse return ctx.fail("CvtBadInput", "anim output malformed", .{});
            if (in_info.comp != 5126 or !std.mem.eql(u8, in_info.ty, "SCALAR")) return ctx.fail("CvtUnsupportedElemType", "clip '{s}': animation input must be f32 SCALAR", .{name});
            const out_elem: []const u8 = if (out_info.comp == 5126 and std.mem.eql(u8, out_info.ty, "VEC3")) "f32x3"
                else if (out_info.comp == 5126 and std.mem.eql(u8, out_info.ty, "VEC4")) "quat"
                else if (out_info.comp == 5126 and std.mem.eql(u8, out_info.ty, "SCALAR")) "f32"
                else return ctx.fail("CvtUnsupportedElemType", "clip '{s}': animation output type {s}/{d} unsupported", .{ name, out_info.ty, out_info.comp });
            const in_sec = c.accSection(@intCast(in_acc), std.fmt.allocPrint(ctx.alloc, "{s}_{s}_in", .{ name, sname }) catch unreachable, try c.g.accessorBytes(ctx, @intCast(in_acc)));
            const out_sec = c.accSection(@intCast(out_acc), std.fmt.allocPrint(ctx.alloc, "{s}_{s}_out", .{ name, sname }) catch unreachable, try c.g.accessorBytes(ctx, @intCast(out_acc)));
            const interp_raw = js(jg(sm, "interpolation") orelse .{ .string = "LINEAR" }) orelse "LINEAR";
            const interp: []const u8 = if (std.mem.eql(u8, interp_raw, "STEP")) "step" else if (std.mem.eql(u8, interp_raw, "CUBICSPLINE")) "cubic-spline" else "linear";
            put(ctx.alloc, &c.txt_clip, "  sampler {s} {{\n    input: f32 @ {s} count {d};\n    output: {s} @ {s} count {d};\n    interpolation: {s};\n  }}\n", .{ sname, in_sec, in_info.count, out_elem, out_sec, out_info.count, interp });
        }
        const channels = ja(jg(an, "channels") orelse .{ .null = {} }) orelse &.{};
        for (channels) |ch| {
            const sm_idx = ji(jg(ch, "sampler") orelse return ctx.fail("CvtBadInput", "channel lacks sampler", .{})) orelse return ctx.fail("CvtBadInput", "channel sampler not int", .{});
            const tgt = jg(ch, "target") orelse return ctx.fail("CvtBadInput", "channel lacks target", .{});
            const tn = ji(jg(tgt, "node") orelse return ctx.fail("CvtBadInput", "channel target lacks node", .{})) orelse return ctx.fail("CvtBadInput", "channel node not int", .{});
            const path = js(jg(tgt, "path") orelse .{ .null = {} }) orelse return ctx.fail("CvtBadInput", "channel lacks path", .{});
            if (!std.mem.eql(u8, path, "translation") and !std.mem.eql(u8, path, "rotation") and !std.mem.eql(u8, path, "scale") and !std.mem.eql(u8, path, "weights"))
                return ctx.fail("CvtBadInput", "channel path '{s}' unknown", .{path});
            put(ctx.alloc, &c.txt_clip, "  channel {{ node: {s}; path: {s}; sampler: {s}; }}\n", .{ c.node_names.items[@intCast(tn)], path, sampler_names.items[@intCast(sm_idx)] });
        }
        put(ctx.alloc, &c.txt_clip, "}}\n", .{});
    }
}

// ---------------- PNG 编码（raw-rgba8 无损重编码） ----------------
fn crc32w(data: []const u8) u32 {
    var crc: u32 = 0xFFFF_FFFF;
    for (data) |byte| { crc ^= byte; for (0..8) |_| crc = (crc >> 1) ^ (0xEDB8_8320 & (0 -% (crc & 1))); }
    return crc ^ 0xFFFF_FFFF;
}
fn pngChunk(alloc: std.mem.Allocator, out: *std.ArrayList(u8), typ: []const u8, data: []const u8) void {
    var lb: [4]u8 = undefined;
    std.mem.writeInt(u32, &lb, @intCast(data.len), .big);
    out.appendSlice(alloc, &lb) catch {};
    out.appendSlice(alloc, typ) catch {};
    out.appendSlice(alloc, data) catch {};
    var cd: std.ArrayList(u8) = .empty;
    cd.appendSlice(alloc, typ) catch {};
    cd.appendSlice(alloc, data) catch {};
    std.mem.writeInt(u32, &lb, crc32w(cd.items), .big);
    out.appendSlice(alloc, &lb) catch {};
}
fn encodePngRgba8(ctx: *Ctx, raw: []const u8, w: u32, h: u32) ![]u8 {
    if (raw.len != @as(usize, w) * h * 4) return ctx.fail("CvtBadInput", "raw-rgba8 payload {d}B != {d}x{d}x4", .{ raw.len, w, h });
    var scan: std.ArrayList(u8) = .empty;
    var y: usize = 0;
    while (y < h) : (y += 1) {
        scan.append(ctx.alloc, 0) catch {};
        scan.appendSlice(ctx.alloc, raw[y * w * 4 ..][0 .. w * 4]) catch {};
    }
    var idat: std.ArrayList(u8) = .empty;
    idat.appendSlice(ctx.alloc, &.{ 0x78, 0x01 }) catch {};
    var off: usize = 0;
    var a: u32 = 1;
    var b: u32 = 0;
    for (scan.items) |byte| { a = (a + byte) % 65521; b = (b + a) % 65521; }
    while (true) {
        const chunk_len = @min(scan.items.len - off, 65535);
        const last = off + chunk_len >= scan.items.len;
        idat.append(ctx.alloc, if (last) @as(u8, 1) else 0) catch {};
        var lb: [2]u8 = undefined;
        std.mem.writeInt(u16, &lb, @intCast(chunk_len), .little);
        idat.appendSlice(ctx.alloc, &lb) catch {};
        std.mem.writeInt(u16, &lb, ~@as(u16, @intCast(chunk_len)), .little);
        idat.appendSlice(ctx.alloc, &lb) catch {};
        idat.appendSlice(ctx.alloc, scan.items[off..][0..chunk_len]) catch {};
        off += chunk_len;
        if (last) break;
    }
    var ab: [4]u8 = undefined;
    std.mem.writeInt(u32, &ab, (b << 16) | a, .big);
    idat.appendSlice(ctx.alloc, &ab) catch {};
    var out: std.ArrayList(u8) = .empty;
    out.appendSlice(ctx.alloc, &.{ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }) catch {};
    var ihdr: [13]u8 = @splat(0);
    std.mem.writeInt(u32, ihdr[0..4], w, .big);
    std.mem.writeInt(u32, ihdr[4..8], h, .big);
    ihdr[8] = 8; ihdr[9] = 6;
    pngChunk(ctx.alloc, &out, "IHDR", &ihdr);
    pngChunk(ctx.alloc, &out, "IDAT", idat.items);
    pngChunk(ctx.alloc, &out, "IEND", &.{});
    return out.items;
}

// ---------------- to-gltf ----------------
const GOut = struct {
    ctx: *Ctx,
    bin: std.ArrayList(u8) = .empty,
    bvs: std.ArrayList([]const u8) = .empty,
    accs: std.ArrayList([]const u8) = .empty,
    acc_cache: std.StringHashMap(usize),
    payloads: std.StringHashMap([]const u8),
    ifaces: std.StringHashMap(ifacemod.Iface),
    used_exts: std.ArrayList([]const u8) = .empty,

    fn addBufferView(self: *GOut, bytes: []const u8) usize {
        const off = self.bin.items.len;
        self.bin.appendSlice(self.ctx.alloc, bytes) catch {};
        const frag = std.fmt.allocPrint(self.ctx.alloc, "{{\"buffer\":0,\"byteOffset\":{d},\"byteLength\":{d}}}", .{ off, bytes.len }) catch unreachable;
        self.bvs.append(self.ctx.alloc, frag) catch {};
        return self.bvs.items.len - 1;
    }
    fn addAccessor(self: *GOut, section: []const u8, bytes: []const u8, comp: u32, ty: []const u8, normalized: bool) usize {
        const key = std.fmt.allocPrint(self.ctx.alloc, "{s}|{d}|{s}|{d}", .{ section, comp, ty, @intFromBool(normalized) }) catch unreachable;
        if (self.acc_cache.get(key)) |ix| return ix;
        const bv = self.addBufferView(bytes);
        const csize: usize = switch (comp) { 5120, 5121 => @as(usize, 1), 5122, 5123 => @as(usize, 2), else => @as(usize, 4) };
        const esize: usize = csize * Gltf.typeComps(ty);
        const count = if (esize > 0) bytes.len / esize else 0;
        const frag = std.fmt.allocPrint(self.ctx.alloc, "{{\"bufferView\":{d},\"componentType\":{d},\"count\":{d},\"type\":\"{s}\"{s}}}", .{ bv, comp, count, ty, if (normalized) ",\"normalized\":true" else "" }) catch unreachable;
        self.accs.append(self.ctx.alloc, frag) catch {};
        const ix = self.accs.items.len - 1;
        self.acc_cache.put(key, ix) catch {};
        return ix;
    }
    fn sectionBytes(self: *GOut, name: []const u8) ![]const u8 {
        return self.payloads.get(name) orelse self.ctx.fail("CvtBadInput", "section '{s}' not present in the split binary", .{name});
    }
};

fn jsonEsc(alloc: std.mem.Allocator, s: []const u8) []const u8 {
    var out: std.ArrayList(u8) = .empty;
    for (s) |c| {
        if (c == '"' or c == '\\') { out.append(alloc, '\\') catch {}; out.append(alloc, c) catch {}; }
        else if (c < 0x20) { const e = std.fmt.allocPrint(alloc, "\\u{x:0>4}", .{c}) catch continue; out.appendSlice(alloc, e) catch {}; }
        else out.append(alloc, c) catch {};
    }
    return out.items;
}
fn joinJson(alloc: std.mem.Allocator, items: []const []const u8) []const u8 {
    var out: std.ArrayList(u8) = .empty;
    for (items, 0..) |it, i| { if (i > 0) out.append(alloc, ',') catch {}; out.appendSlice(alloc, it) catch {}; }
    return out.items;
}

fn toGltf(ctx: *Ctx, text_path: []const u8, bin_path: []const u8, outdir: []const u8, iface_specs: []const []const u8, std_shaders: []const []const u8) !void {
    const src = try ctx.readFile(text_path);
    var ifaces: std.StringHashMap(ifacemod.Iface) = .init(ctx.alloc);
    for (iface_specs) |sp| {
        const eq = std.mem.indexOfScalar(u8, sp, '=') orelse return ctx.fail("CvtBadInput", "--iface expects <Shader>=<file>", .{});
        const fsrc = try ctx.readFile(sp[eq + 1 ..]);
        ifaces.put(sp[0..eq], ifacemod.parseIface(ctx.alloc, fsrc, &ctx.diags, sp[0..eq])) catch {};
    }
    var rdiags = model.Diags.init(ctx.alloc);
    var ast = parse.parse(ctx.alloc, src, .authoring, &.{}, &rdiags) catch {
        rdiags.printAll();
        return ctx.fail("CvtBadInput", "SAX3D input does not parse", .{});
    };
    _ = checkmod.check(ctx.alloc, &ast, &ifaces, &rdiags);
    if (rdiags.count() > 0) {
        rdiags.printAll();
        return ctx.fail("CvtBadInput", "SAX3D input fails the referee ({d} diagnostics); refusing to convert", .{rdiags.count()});
    }
    // 段载荷（取自拆分二进制，段表是长度真理）
    const bin_bytes = try ctx.readFile(bin_path);
    const hdr = binio.parseHeader(bin_bytes, &rdiags) orelse return ctx.fail("CvtBadInput", "binary header invalid", .{});
    if (hdr.form != .split) return ctx.fail("CvtBadInput", "to-gltf expects a split-form .saxb3d", .{});
    if (!binio.tableFits(bin_bytes, hdr)) return ctx.fail("CvtBadInput", "binary truncated", .{});
    var go = GOut{ .ctx = ctx, .acc_cache = .init(ctx.alloc), .payloads = .init(ctx.alloc), .ifaces = ifaces };
    {
        var i: usize = 0;
        while (i < hdr.section_count) : (i += 1) {
            const rec = binio.readRec(bin_bytes, i);
            const nm = binio.nameAt(bin_bytes, hdr, rec.name_off) orelse return ctx.fail("CvtBadInput", "binary section name unresolvable", .{});
            if (rec.offset + rec.len > bin_bytes.len) return ctx.fail("CvtBadInput", "binary section '{s}' overruns file", .{nm});
            try go.payloads.put(nm, bin_bytes[@intCast(rec.offset)..@intCast(rec.offset + rec.len)]);
        }
    }
    const alloc = ctx.alloc;
    const text_dir = std.fs.path.dirname(text_path) orelse ".";
    // ---- 图像 ----
    var img_frags: std.ArrayList([]const u8) = .empty;
    for (ast.images.items) |im| {
        var bytes: []const u8 = undefined;
        var mime: []const u8 = undefined;
        if (std.mem.startsWith(u8, im.format, "raw-")) {
            if (!std.mem.eql(u8, im.format, "raw-rgba8")) return ctx.fail("CvtUnsupportedImageFormat", "image '{s}': {s} cannot be PNG-encoded without value reinterpretation (f16 payloads); loudly unsupported", .{ im.name, im.format });
            const sz = im.size orelse return ctx.fail("CvtBadInput", "image '{s}': raw format lacks size (referee should have caught this)", .{im.name});
            bytes = try encodePngRgba8(ctx, try go.sectionBytes(im.source), @intCast(sz[0]), @intCast(sz[1]));
            mime = "image/png";
            ctx.ledger.add("APPROX", "image '{s}': raw-rgba8 losslessly PNG-encoded for glTF (representation change, pixels identical)", .{im.name});
        } else {
            if (im.source_kind == .section) {
                bytes = try go.sectionBytes(im.source);
            } else {
                const full = std.fmt.allocPrint(alloc, "{s}/{s}", .{ text_dir, im.source }) catch unreachable;
                bytes = try ctx.readFile(full);
                ctx.ledger.add("APPROX", "image '{s}': path-source file embedded as bufferView; the path reference itself is not preserved in glTF output", .{im.name});
            }
            mime = if (std.mem.eql(u8, im.format, "png")) "image/png" else if (std.mem.eql(u8, im.format, "jpeg")) "image/jpeg" else if (std.mem.eql(u8, im.format, "ktx2")) "image/ktx2" else return ctx.fail("CvtBadInput", "image '{s}': format '{s}' has no glTF mime", .{ im.name, im.format });
        }
        const bv = go.addBufferView(bytes);
        try img_frags.append(alloc, std.fmt.allocPrint(alloc, "{{\"name\":\"{s}\",\"bufferView\":{d},\"mimeType\":\"{s}\"}}", .{ jsonEsc(alloc, im.name), bv, mime }) catch unreachable);
    }
    // ---- 采样器/纹理 ----
    var smp_frags: std.ArrayList([]const u8) = .empty;
    var tex_frags: std.ArrayList([]const u8) = .empty;
    var tex_index: std.StringHashMap(usize) = .init(alloc);
    for (ast.textures.items, 0..) |t, ti2| {
        const s = t.sampler;
        const mag: u32 = if (s.mag != null and std.mem.eql(u8, s.mag.?, "nearest")) 9728 else 9729;
        const minf: u32 = blk: {
            const mn = s.min orelse "linear";
            const mp = s.mipmap orelse "none";
            if (std.mem.eql(u8, mp, "none")) break :blk if (std.mem.eql(u8, mn, "nearest")) @as(u32, 9728) else 9729;
            if (std.mem.eql(u8, mp, "nearest")) break :blk if (std.mem.eql(u8, mn, "nearest")) @as(u32, 9984) else 9986;
            break :blk if (std.mem.eql(u8, mn, "nearest")) @as(u32, 9985) else 9987;
        };
        const wu: u32 = if (s.wrap_u) |w| (if (std.mem.eql(u8, w, "clamp")) @as(u32, 33071) else if (std.mem.eql(u8, w, "mirror")) @as(u32, 33648) else 10497) else 10497;
        const wv: u32 = if (s.wrap_v) |w| (if (std.mem.eql(u8, w, "clamp")) @as(u32, 33071) else if (std.mem.eql(u8, w, "mirror")) @as(u32, 33648) else 10497) else 10497;
        if (s.wrap_w) |ww| ctx.ledger.add("LOSS", "texture '{s}': sampler wrap_w '{s}' has no glTF 2D counterpart; dropped", .{ t.name, ww });
        try smp_frags.append(alloc, std.fmt.allocPrint(alloc, "{{\"magFilter\":{d},\"minFilter\":{d},\"wrapS\":{d},\"wrapT\":{d}}}", .{ mag, minf, wu, wv }) catch unreachable);
        var img_idx: usize = 0;
        for (ast.images.items, 0..) |im, ii| { if (std.mem.eql(u8, im.name, t.image)) img_idx = ii; }
        try tex_frags.append(alloc, std.fmt.allocPrint(alloc, "{{\"name\":\"{s}\",\"source\":{d},\"sampler\":{d}}}", .{ jsonEsc(alloc, t.name), img_idx, ti2 }) catch unreachable);
        try tex_index.put(t.name, ti2);
    }
    // ---- 材质 ----
    var mat_frags: std.ArrayList([]const u8) = .empty;
    var mat_index: std.StringHashMap(usize) = .init(alloc);
    for (ast.materials.items, 0..) |m, mi2| {
        try mat_index.put(m.name, mi2);

        var extras: std.ArrayList(u8) = .empty;
        put(alloc, &extras, "\"sax3d_shader\":\"{s}\"", .{jsonEsc(alloc, m.shader)});
        var is_std = std.mem.startsWith(u8, m.shader, "StdPbr");
        for (std_shaders) |ss| { if (std.mem.eql(u8, ss, m.shader)) is_std = true; }
        if (is_std) ctx.ledger.add("APPROX", "material '{s}': standard shader '{s}' represented by the PBR parameter set; name kept in extras.sax3d_shader", .{ m.name, m.shader })
        else ctx.ledger.add("LOSS", "material '{s}': CUSTOM shader '{s}' logic is not expressible in glTF; only PBR-approximable params mapped, name kept in extras.sax3d_shader", .{ m.name, m.shader });
        var pbr_parts: std.ArrayList([]const u8) = .empty;
        for (m.params.items) |p| {
            if (std.mem.eql(u8, p.name, "base_color")) {
                if (p.lit == .vec and p.lit.vec.len == 4) {
                    const v = p.lit.vec;
                    if (!(v[0] == 1 and v[1] == 1 and v[2] == 1 and v[3] == 1))
                        try pbr_parts.append(alloc, std.fmt.allocPrint(alloc, "\"baseColorFactor\":[{d},{d},{d},{d}]", .{ v[0], v[1], v[2], v[3] }) catch unreachable);
                }
            } else if (std.mem.eql(u8, p.name, "roughness")) {
                if (p.lit == .scalar) try pbr_parts.append(alloc, std.fmt.allocPrint(alloc, "\"roughnessFactor\":{d}", .{p.lit.scalar}) catch unreachable);
            } else if (std.mem.eql(u8, p.name, "metallic")) {
                // 在统一 metallic 处理处写出（见下）
            } else {
                ctx.ledger.add("LOSS", "material '{s}': param '{s}' has no glTF PBR counterpart; dropped", .{ m.name, p.name });
            }
        }
        // metallic 恒显式（有效值 = 参数 ?? 夹具默认 ?? glTF 默认 1.0 并记账）
        var metal: f64 = 1.0;
        var metal_found = false;
        for (m.params.items) |p| { if (std.mem.eql(u8, p.name, "metallic") and p.lit == .scalar) { metal = p.lit.scalar; metal_found = true; } }
        if (!metal_found) {
            if (go.ifaces.get(m.shader)) |fx| { if (fx.params.get("metallic")) |fp| { if (fp.has_default) { if (fp.default_scalar) |dv| { metal = dv; metal_found = true; } } } }
            if (!metal_found) ctx.ledger.add("APPROX", "material '{s}': metallic neither set nor defaulted by fixture; glTF default 1.0 written explicitly", .{m.name});
        }
        try pbr_parts.append(alloc, std.fmt.allocPrint(alloc, "\"metallicFactor\":{d}", .{metal}) catch unreachable);
        for (m.texbinds.items) |tb| {
            if (std.mem.eql(u8, tb.name, "base_color_map")) {
                const tix = tex_index.get(tb.texture) orelse return ctx.fail("CvtBadInput", "texture '{s}' unknown", .{tb.texture});
                var tt_part: []const u8 = "";
                for (m.tex_transforms.items) |tt2| {
                    if (std.mem.eql(u8, tt2.name, "base_color_map")) {
                        var inner: std.ArrayList(u8) = .empty;
                        var first = true;
                        if (tt2.offset) |o| { put(alloc, &inner, "\"offset\":[{d},{d}]", .{ o[0], o[1] }); first = false; }
                        if (tt2.scale) |sc| { if (!first) put(alloc, &inner, ",", .{}); put(alloc, &inner, "\"scale\":[{d},{d}]", .{ sc[0], sc[1] }); first = false; }
                        if (tt2.rotation) |r| { if (!first) put(alloc, &inner, ",", .{}); put(alloc, &inner, "\"rotation\":{d}", .{r}); }
                        tt_part = std.fmt.allocPrint(alloc, ",\"extensions\":{{\"KHR_texture_transform\":{{{s}}}}}", .{inner.items}) catch unreachable;
                        var has_ext = false;
                        for (go.used_exts.items) |e| { if (std.mem.eql(u8, e, "KHR_texture_transform")) has_ext = true; }
                        if (!has_ext) go.used_exts.append(alloc, "KHR_texture_transform") catch {};
                    }
                }
                try pbr_parts.append(alloc, std.fmt.allocPrint(alloc, "\"baseColorTexture\":{{\"index\":{d}{s}}}", .{ tix, tt_part }) catch unreachable);
            } else {
                ctx.ledger.add("LOSS", "material '{s}': texture binding '{s}' has no glTF PBR slot; dropped", .{ m.name, tb.name });
            }
        }
        var frag: std.ArrayList(u8) = .empty;
        put(alloc, &frag, "{{\"name\":\"{s}\",\"pbrMetallicRoughness\":{{{s}}}", .{ jsonEsc(alloc, m.name), joinJson(alloc, pbr_parts.items) });
        if (m.alpha) |a| { if (std.mem.eql(u8, a, "blend")) put(alloc, &frag, ",\"alphaMode\":\"BLEND\"", .{}); if (std.mem.eql(u8, a, "mask")) { put(alloc, &frag, ",\"alphaMode\":\"MASK\"", .{}); if (m.cutoff) |co| put(alloc, &frag, ",\"alphaCutoff\":{d}", .{co}); } }
        if (m.double_sided) |ds| { if (ds) put(alloc, &frag, ",\"doubleSided\":true", .{}); }
        if (m.depth_write) |dw| {
            ctx.ledger.add("LOSS", "material '{s}': state depth_write={s} has no glTF core counterpart; recorded in extras only", .{ m.name, if (dw) "true" else "false" });
            put(alloc, &extras, ",\"sax3d_depth_write\":{s}", .{if (dw) "true" else "false"});
        }
        put(alloc, &frag, ",\"extras\":{{{s}}}}}", .{extras.items});
        try mat_frags.append(alloc, frag.items);
    }
    // ---- 网格 ----
    var mesh_frags: std.ArrayList([]const u8) = .empty;
    var mesh_index: std.StringHashMap(usize) = .init(alloc);
    for (ast.meshes.items, 0..) |m, mi2| {
        try mesh_index.put(m.name, mi2);
        var attrs: std.ArrayList([]const u8) = .empty;
        const chan_map = [_]struct { role: []const u8, key: []const u8, comp: u32, ty: []const u8 }{
            .{ .role = "position", .key = "POSITION", .comp = 5126, .ty = "VEC3" },
            .{ .role = "normal", .key = "NORMAL", .comp = 5126, .ty = "VEC3" },
            .{ .role = "tangent", .key = "TANGENT", .comp = 5126, .ty = "VEC4" },
            .{ .role = "uv0", .key = "TEXCOORD_0", .comp = 5126, .ty = "VEC2" },
            .{ .role = "uv1", .key = "TEXCOORD_1", .comp = 5126, .ty = "VEC2" },
            .{ .role = "uv2", .key = "TEXCOORD_2", .comp = 5126, .ty = "VEC2" },
            .{ .role = "uv3", .key = "TEXCOORD_3", .comp = 5126, .ty = "VEC2" },
            .{ .role = "joints0", .key = "JOINTS_0", .comp = 5123, .ty = "VEC4" },
            .{ .role = "weights0", .key = "WEIGHTS_0", .comp = 5126, .ty = "VEC4" },
        };
        for (m.channels.items) |ch| {
            if (ch.custom) {
                const et = lib.schema.elemType(ch.ty) orelse return ctx.fail("CvtBadInput", "attr type unknown", .{});
                _ = et;
                const ct = elemToCompTy(ch.ty) orelse return ctx.fail("CvtUnsupportedElemType", "attr '{s}' type {s} has no glTF accessor form", .{ ch.name, ch.ty });
                const ax = go.addAccessor(ch.section, try go.sectionBytes(ch.section), ct.comp, ct.tyn, false);
                try attrs.append(alloc, std.fmt.allocPrint(alloc, "\"_{s}\":{d}", .{ jsonEsc(alloc, ch.name), ax }) catch unreachable);
                continue;
            }
            if (std.mem.eql(u8, ch.name, "color0")) {
                const is_u8 = std.mem.eql(u8, ch.ty, "u8x4");
                const ax = go.addAccessor(ch.section, try go.sectionBytes(ch.section), if (is_u8) 5121 else 5126, "VEC4", is_u8);
                try attrs.append(alloc, std.fmt.allocPrint(alloc, "\"COLOR_0\":{d}", .{ax}) catch unreachable);
                continue;
            }
            for (chan_map) |cm| {
                if (std.mem.eql(u8, ch.name, cm.role)) {
                    const ax = go.addAccessor(ch.section, try go.sectionBytes(ch.section), cm.comp, cm.ty, false);
                    try attrs.append(alloc, std.fmt.allocPrint(alloc, "\"{s}\":{d}", .{ cm.key, ax }) catch unreachable);
                }
            }
        }
        var idx_acc: ?usize = null;
        if (m.idx_ty) |ity| {
            idx_acc = go.addAccessor(m.idx_section, try go.sectionBytes(m.idx_section), if (std.mem.eql(u8, ity, "u16")) 5123 else 5125, "SCALAR", false);
        }
        const mode: u32 = if (std.mem.eql(u8, m.topology, "points")) 0 else if (std.mem.eql(u8, m.topology, "lines")) 1 else if (std.mem.eql(u8, m.topology, "line-strip")) 3 else if (std.mem.eql(u8, m.topology, "triangle-strip")) 5 else if (std.mem.eql(u8, m.topology, "triangle-fan")) 6 else 4;
        // morph 目标（全部 primitive 共享同一 targets 集）
        var targets_frag: []const u8 = "";
        if (m.morphs.items.len > 0) {
            var tlist: std.ArrayList([]const u8) = .empty;
            for (m.morphs.items) |mo| {
                var tparts: std.ArrayList([]const u8) = .empty;
                for (mo.channels.items) |ch| {
                    const key: []const u8 = if (std.mem.eql(u8, ch.name, "position")) "POSITION" else if (std.mem.eql(u8, ch.name, "normal")) "NORMAL" else "TANGENT";
                    const ax = go.addAccessor(ch.section, try go.sectionBytes(ch.section), 5126, if (std.mem.eql(u8, ch.name, "tangent")) "VEC4" else "VEC3", false);
                    try tparts.append(alloc, std.fmt.allocPrint(alloc, "\"{s}\":{d}", .{ key, ax }) catch unreachable);
                }
                try tlist.append(alloc, std.fmt.allocPrint(alloc, "{{{s}}}", .{joinJson(alloc, tparts.items)}) catch unreachable);
            }
            targets_frag = std.fmt.allocPrint(alloc, ",\"targets\":[{s}]", .{joinJson(alloc, tlist.items)}) catch unreachable;
        }
        var prim_frags: std.ArrayList([]const u8) = .empty;
        for (m.prims.items) |pr| {
            const matx = mat_index.get(pr.material) orelse return ctx.fail("CvtBadInput", "material '{s}' unknown", .{pr.material});
            var pf: std.ArrayList(u8) = .empty;
            put(alloc, &pf, "{{\"attributes\":{{{s}}}", .{joinJson(alloc, attrs.items)});
            if (idx_acc) |ia| put(alloc, &pf, ",\"indices\":{d}", .{ia});
            put(alloc, &pf, ",\"material\":{d},\"mode\":{d}{s}}}", .{ matx, mode, targets_frag });
            try prim_frags.append(alloc, pf.items);
        }
        if (m.prims.items.len > 1 and idx_acc != null)
            ctx.ledger.add("APPROX", "mesh '{s}': {d} SAX3D primitives share one index set; glTF primitives will overlap-draw (SAX3D v1 primitives carry no index ranges — map §1)", .{ m.name, m.prims.items.len });
        var mf: std.ArrayList(u8) = .empty;
        put(alloc, &mf, "{{\"name\":\"{s}\",\"primitives\":[{s}]", .{ jsonEsc(alloc, m.name), joinJson(alloc, prim_frags.items) });
        if (m.morphs.items.len > 0) {
            var names: std.ArrayList([]const u8) = .empty;
            for (m.morphs.items) |mo| try names.append(alloc, std.fmt.allocPrint(alloc, "\"{s}\"", .{jsonEsc(alloc, mo.name)}) catch unreachable);
            put(alloc, &mf, ",\"extras\":{{\"targetNames\":[{s}]}}", .{joinJson(alloc, names.items)});
        }
        put(alloc, &mf, "}}", .{});
        try mesh_frags.append(alloc, mf.items);
    }
    // ---- 场景/节点（skin 索引按骨骼声明序预分配） ----
    var skin_index: std.StringHashMap(usize) = .init(alloc);
    for (ast.skeletons.items, 0..) |sk, si2| try skin_index.put(sk.name, si2);
    var node_frags: std.ArrayList([]const u8) = .empty;
    var node_index: std.StringHashMap(usize) = .init(alloc);
    var scene_frags: std.ArrayList([]const u8) = .empty;
    for (ast.scenes.items) |sc| {
        var roots: std.ArrayList(usize) = .empty;
        for (sc.roots.items) |*rn| try roots.append(alloc, try emitNodeG(ctx, &go, &ast, rn, &node_frags, &node_index, &mesh_frags, &mesh_index, &mat_index, &skin_index));
        var rlist: std.ArrayList([]const u8) = .empty;
        for (roots.items) |r| try rlist.append(alloc, std.fmt.allocPrint(alloc, "{d}", .{r}) catch unreachable);
        try scene_frags.append(alloc, std.fmt.allocPrint(alloc, "{{\"name\":\"{s}\",\"nodes\":[{s}]}}", .{ jsonEsc(alloc, sc.name), joinJson(alloc, rlist.items) }) catch unreachable);
    }
    // ---- 骨骼 → skin ----
    var skin_frags: std.ArrayList([]const u8) = .empty;
    for (ast.skeletons.items) |sk| {
        var jlist: std.ArrayList([]const u8) = .empty;
        for (sk.joints.items) |j| {
            const nx = node_index.get(j.name) orelse return ctx.fail("CvtBadInput", "joint '{s}' has no scene node", .{j.name});
            try jlist.append(alloc, std.fmt.allocPrint(alloc, "{d}", .{nx}) catch unreachable);
        }
        var ib_part: []const u8 = "";
        if (sk.ib_section) |sec| {
            const ax = go.addAccessor(sec, try go.sectionBytes(sec), 5126, "MAT4", false);
            ib_part = std.fmt.allocPrint(alloc, ",\"inverseBindMatrices\":{d}", .{ax}) catch unreachable;
        }
        try skin_frags.append(alloc, std.fmt.allocPrint(alloc, "{{\"name\":\"{s}\",\"joints\":[{s}]{s}}}", .{ jsonEsc(alloc, sk.name), joinJson(alloc, jlist.items), ib_part }) catch unreachable);
    }
    // ---- 动画 ----
    var anim_frags: std.ArrayList([]const u8) = .empty;
    for (ast.clips.items) |cl| {
        var smp_frags2: std.ArrayList([]const u8) = .empty;
        var smp_index: std.StringHashMap(usize) = .init(alloc);
        for (cl.samplers.items, 0..) |sm, sj| {
            try smp_index.put(sm.name, sj);
            const in_ax = go.addAccessor(sm.in_section, try go.sectionBytes(sm.in_section), 5126, "SCALAR", false);
            const out_ty: []const u8 = if (std.mem.eql(u8, sm.out_ty, "f32x3")) "VEC3" else if (std.mem.eql(u8, sm.out_ty, "f32")) "SCALAR" else "VEC4";
            const out_ax = go.addAccessor(sm.out_section, try go.sectionBytes(sm.out_section), 5126, out_ty, false);
            const interp: []const u8 = if (std.mem.eql(u8, sm.interpolation, "step")) "STEP" else if (std.mem.eql(u8, sm.interpolation, "cubic-spline")) "CUBICSPLINE" else "LINEAR";
            try smp_frags2.append(alloc, std.fmt.allocPrint(alloc, "{{\"input\":{d},\"interpolation\":\"{s}\",\"output\":{d}}}", .{ in_ax, interp, out_ax }) catch unreachable);
        }
        var ch_frags: std.ArrayList([]const u8) = .empty;
        for (cl.channels.items) |ch| {
            const nx = node_index.get(ch.node) orelse return ctx.fail("CvtBadInput", "clip channel node '{s}' not in any scene", .{ch.node});
            const sx = smp_index.get(ch.sampler) orelse return ctx.fail("CvtBadInput", "clip sampler '{s}' unknown", .{ch.sampler});
            try ch_frags.append(alloc, std.fmt.allocPrint(alloc, "{{\"sampler\":{d},\"target\":{{\"node\":{d},\"path\":\"{s}\"}}}}", .{ sx, nx, ch.path }) catch unreachable);
        }
        try anim_frags.append(alloc, std.fmt.allocPrint(alloc, "{{\"name\":\"{s}\",\"channels\":[{s}],\"samplers\":[{s}]}}", .{ jsonEsc(alloc, cl.name), joinJson(alloc, ch_frags.items), joinJson(alloc, smp_frags2.items) }) catch unreachable);
    }
    // ---- 组装 JSON / 写出 ----
    var j: std.ArrayList(u8) = .empty;
    put(alloc, &j, "{{\"asset\":{{\"version\":\"2.0\",\"generator\":\"sax3dcvt\"}}", .{});
    if (scene_frags.items.len > 0) put(alloc, &j, ",\"scene\":0,\"scenes\":[{s}]", .{joinJson(alloc, scene_frags.items)});
    if (node_frags.items.len > 0) put(alloc, &j, ",\"nodes\":[{s}]", .{joinJson(alloc, node_frags.items)});
    if (mesh_frags.items.len > 0) put(alloc, &j, ",\"meshes\":[{s}]", .{joinJson(alloc, mesh_frags.items)});
    if (mat_frags.items.len > 0) put(alloc, &j, ",\"materials\":[{s}]", .{joinJson(alloc, mat_frags.items)});
    if (tex_frags.items.len > 0) put(alloc, &j, ",\"textures\":[{s}]", .{joinJson(alloc, tex_frags.items)});
    if (smp_frags.items.len > 0) put(alloc, &j, ",\"samplers\":[{s}]", .{joinJson(alloc, smp_frags.items)});
    if (img_frags.items.len > 0) put(alloc, &j, ",\"images\":[{s}]", .{joinJson(alloc, img_frags.items)});
    if (skin_frags.items.len > 0) put(alloc, &j, ",\"skins\":[{s}]", .{joinJson(alloc, skin_frags.items)});
    if (anim_frags.items.len > 0) put(alloc, &j, ",\"animations\":[{s}]", .{joinJson(alloc, anim_frags.items)});
    if (go.used_exts.items.len > 0) {
        var el: std.ArrayList([]const u8) = .empty;
        for (go.used_exts.items) |e| try el.append(alloc, std.fmt.allocPrint(alloc, "\"{s}\"", .{e}) catch unreachable);
        put(alloc, &j, ",\"extensionsUsed\":[{s}]", .{joinJson(alloc, el.items)});
    }
    const base0 = if (ast.name.len > 0) ast.name else "asset";
    put(alloc, &j, ",\"bufferViews\":[{s}],\"accessors\":[{s}],\"buffers\":[{{\"byteLength\":{d},\"uri\":\"{s}.bin\"}}]}}", .{ joinJson(alloc, go.bvs.items), joinJson(alloc, go.accs.items), go.bin.items.len, base0 });
    std.Io.Dir.cwd().createDirPath(ctx.io, outdir) catch {};
    const base = if (ast.name.len > 0) ast.name else "asset";
    const gltf_path = std.fmt.allocPrint(alloc, "{s}/{s}.gltf", .{ outdir, base }) catch unreachable;
    const bin_path2 = std.fmt.allocPrint(alloc, "{s}/{s}.bin", .{ outdir, base }) catch unreachable;
    const glb_path = std.fmt.allocPrint(alloc, "{s}/{s}.glb", .{ outdir, base }) catch unreachable;
    std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = gltf_path, .data = j.items }) catch |e| return ctx.fail("CvtBadInput", "write gltf failed: {s}", .{@errorName(e)});
    std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = bin_path2, .data = go.bin.items }) catch |e| return ctx.fail("CvtBadInput", "write bin failed: {s}", .{@errorName(e)});
    // GLB
    var glb: std.ArrayList(u8) = .empty;
    const jp = (4 - (j.items.len % 4)) % 4;
    const bp = (4 - (go.bin.items.len % 4)) % 4;
    const total = 12 + 8 + j.items.len + jp + 8 + go.bin.items.len + bp;
    var hb: [4]u8 = undefined;
    std.mem.writeInt(u32, &hb, 0x46546C67, .little); glb.appendSlice(alloc, &hb) catch {};
    std.mem.writeInt(u32, &hb, 2, .little); glb.appendSlice(alloc, &hb) catch {};
    std.mem.writeInt(u32, &hb, @intCast(total), .little); glb.appendSlice(alloc, &hb) catch {};
    std.mem.writeInt(u32, &hb, @intCast(j.items.len + jp), .little); glb.appendSlice(alloc, &hb) catch {};
    std.mem.writeInt(u32, &hb, 0x4E4F534A, .little); glb.appendSlice(alloc, &hb) catch {};
    glb.appendSlice(alloc, j.items) catch {};
    for (0..jp) |_| glb.append(alloc, ' ') catch {};
    std.mem.writeInt(u32, &hb, @intCast(go.bin.items.len + bp), .little); glb.appendSlice(alloc, &hb) catch {};
    std.mem.writeInt(u32, &hb, 0x004E4942, .little); glb.appendSlice(alloc, &hb) catch {};
    glb.appendSlice(alloc, go.bin.items) catch {};
    for (0..bp) |_| glb.append(alloc, 0) catch {};
    std.Io.Dir.cwd().writeFile(ctx.io, .{ .sub_path = glb_path, .data = glb.items }) catch |e| return ctx.fail("CvtBadInput", "write glb failed: {s}", .{@errorName(e)});
    std.debug.print("WROTE {s} / .bin / .glb (json {d}B, bin {d}B)\n", .{ gltf_path, j.items.len, go.bin.items.len });
}

fn elemToCompTy(ty: []const u8) ?struct { comp: u32, tyn: []const u8 } {
    if (std.mem.eql(u8, ty, "f32")) return .{ .comp = 5126, .tyn = "SCALAR" };
    if (std.mem.eql(u8, ty, "f32x2")) return .{ .comp = 5126, .tyn = "VEC2" };
    if (std.mem.eql(u8, ty, "f32x3")) return .{ .comp = 5126, .tyn = "VEC3" };
    if (std.mem.eql(u8, ty, "f32x4")) return .{ .comp = 5126, .tyn = "VEC4" };
    if (std.mem.eql(u8, ty, "quat")) return .{ .comp = 5126, .tyn = "VEC4" };
    if (std.mem.eql(u8, ty, "u8x4")) return .{ .comp = 5121, .tyn = "VEC4" };
    if (std.mem.eql(u8, ty, "u16x4")) return .{ .comp = 5123, .tyn = "VEC4" };
    if (std.mem.eql(u8, ty, "u32")) return .{ .comp = 5125, .tyn = "SCALAR" };
    if (std.mem.eql(u8, ty, "u16")) return .{ .comp = 5123, .tyn = "SCALAR" };
    if (std.mem.eql(u8, ty, "f32x4x4")) return .{ .comp = 5126, .tyn = "MAT4" };
    return null;
}

// node 发射（to-gltf）：返回分配的 glTF node 索引
fn emitNodeG(ctx: *Ctx, go: *GOut, ast: *const model.Asset, n: *const model.NodeDecl, node_frags: *std.ArrayList([]const u8), node_index: *std.StringHashMap(usize), mesh_frags: *std.ArrayList([]const u8), mesh_index: *std.StringHashMap(usize), mat_index: *std.StringHashMap(usize), skin_index: *std.StringHashMap(usize)) !usize {
    const alloc = ctx.alloc;
    const my_idx = node_frags.items.len;
    try node_index.put(n.name, my_idx);
    try node_frags.append(alloc, ""); // 占位，子节点递归后回填
    var child_idx: std.ArrayList(usize) = .empty;
    for (n.children.items) |*ch| try child_idx.append(alloc, try emitNodeG(ctx, go, ast, ch, node_frags, node_index, mesh_frags, mesh_index, mat_index, skin_index));
    var f: std.ArrayList(u8) = .empty;
    put(alloc, &f, "{{\"name\":\"{s}\"", .{jsonEsc(alloc, n.name)});
    if (n.matrix) |mv| {
        var parts: std.ArrayList([]const u8) = .empty;
        for (mv) |v| try parts.append(alloc, std.fmt.allocPrint(alloc, "{d}", .{v}) catch unreachable);
        put(alloc, &f, ",\"matrix\":[{s}]", .{joinJson(alloc, parts.items)});
    } else if (n.transform) |tr| {
        if (tr.t) |v| put(alloc, &f, ",\"translation\":[{d},{d},{d}]", .{ v[0], v[1], v[2] });
        if (tr.r) |v| put(alloc, &f, ",\"rotation\":[{d},{d},{d},{d}]", .{ v[0], v[1], v[2], v[3] });
        if (tr.s) |v| put(alloc, &f, ",\"scale\":[{d},{d},{d}]", .{ v[0], v[1], v[2] });
    }
    if (n.mesh) |mn| {
        var mx = mesh_index.get(mn) orelse return ctx.fail("CvtBadInput", "mesh '{s}' unknown", .{mn});
        if (n.material) |ovr| {
            // 节点级材质覆盖：克隆 mesh（referee 已保证单 primitive）
            const src_frag = mesh_frags.items[mx];
            _ = src_frag;
            var src_mesh: ?*const model.MeshDecl = null;
            for (ast.meshes.items) |*mm| { if (std.mem.eql(u8, mm.name, mn)) src_mesh = mm; }
            const sm = src_mesh orelse return ctx.fail("CvtBadInput", "mesh '{s}' not found", .{mn});
            if (sm.prims.items.len != 1) return ctx.fail("CvtBadInput", "node '{s}': material override on multi-primitive mesh (referee should have caught)", .{n.name});
            // 以覆盖材质重建一份单 prim mesh 片段：复用原片段的 attributes/targets 串不可直接得，改为深拷贝 AST 路径重建——简化：克隆原片段并替换 material 索引
            const old_mat = mat_index.get(sm.prims.items[0].material) orelse 0;
            const new_mat = mat_index.get(ovr) orelse return ctx.fail("CvtBadInput", "override material '{s}' unknown", .{ovr});
            const needle = std.fmt.allocPrint(alloc, "\"material\":{d}", .{old_mat}) catch unreachable;
            const repl = std.fmt.allocPrint(alloc, "\"material\":{d}", .{new_mat}) catch unreachable;
            var clone: std.ArrayList(u8) = .empty;
            clone.appendSlice(alloc, mesh_frags.items[mx]) catch {};
            if (std.mem.indexOf(u8, clone.items, needle)) |pos| {
                var nf: std.ArrayList(u8) = .empty;
                nf.appendSlice(alloc, clone.items[0..pos]) catch {};
                nf.appendSlice(alloc, repl) catch {};
                nf.appendSlice(alloc, clone.items[pos + needle.len ..]) catch {};
                clone = nf;
            }
            // 改名
            const old_name = std.fmt.allocPrint(alloc, "\"name\":\"{s}\"", .{jsonEsc(alloc, mn)}) catch unreachable;
            const new_name = std.fmt.allocPrint(alloc, "\"name\":\"{s}__ovr_{s}\"", .{ jsonEsc(alloc, mn), jsonEsc(alloc, n.name) }) catch unreachable;
            if (std.mem.indexOf(u8, clone.items, old_name)) |pos| {
                var nf: std.ArrayList(u8) = .empty;
                nf.appendSlice(alloc, clone.items[0..pos]) catch {};
                nf.appendSlice(alloc, new_name) catch {};
                nf.appendSlice(alloc, clone.items[pos + old_name.len ..]) catch {};
                clone = nf;
            }
            try mesh_frags.append(alloc, clone.items);
            mx = mesh_frags.items.len - 1;
            try mesh_index.put(std.fmt.allocPrint(alloc, "{s}__ovr_{s}", .{ mn, n.name }) catch unreachable, mx);
            ctx.ledger.add("APPROX", "node '{s}': SAX3D material override '{s}' has no glTF node-level form; mesh cloned as '{s}__ovr_{s}'", .{ n.name, ovr, mn, n.name });
        }
        put(alloc, &f, ",\"mesh\":{d}", .{mx});
    }
    if (n.skin) |sn| {
        const sx = skin_index.get(sn) orelse return ctx.fail("CvtBadInput", "skin '{s}' unknown", .{sn});
        put(alloc, &f, ",\"skin\":{d}", .{sx});
    }
    if (child_idx.items.len > 0) {
        var parts: std.ArrayList([]const u8) = .empty;
        for (child_idx.items) |ci| try parts.append(alloc, std.fmt.allocPrint(alloc, "{d}", .{ci}) catch unreachable);
        put(alloc, &f, ",\"children\":[{s}]", .{joinJson(alloc, parts.items)});
    }
    put(alloc, &f, "}}", .{});
    node_frags.items[my_idx] = f.items;
    return my_idx;
}

// ---------------- main ----------------
pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    var ctx = Ctx{ .alloc = alloc, .io = init.io, .diags = model.Diags.init(alloc), .ledger = .{ .alloc = alloc } };
    const argv = try init.minimal.args.toSlice(alloc);
    if (argv.len < 2) { std.debug.print("usage: convert <to-sax3d|to-gltf> ...\n", .{}); std.process.exit(2); }
    var code: u8 = 0;
    if (std.mem.eql(u8, argv[1], "to-sax3d")) {
        if (argv.len < 4) { std.debug.print("usage: convert to-sax3d <in.gltf|in.glb> <outdir> [--fixtures-dir <dir>]\n", .{}); std.process.exit(2); }
        var fixtures_dir: []const u8 = "converter/fixtures";
        var i: usize = 4;
        while (i < argv.len) : (i += 1) {
            if (std.mem.eql(u8, argv[i], "--fixtures-dir") and i + 1 < argv.len) { i += 1; fixtures_dir = argv[i]; }
        }
        toSax3d(&ctx, argv[2], argv[3], fixtures_dir) catch |e| switch (e) {
            error.ConvertFailed => code = 1,
            else => { ctx.diags.add("CvtBadInput", "unexpected: {s}", .{@errorName(e)}); code = 1; },
        };
    } else if (std.mem.eql(u8, argv[1], "to-gltf")) {
        if (argv.len < 5) { std.debug.print("usage: convert to-gltf <in.sax3d> <in.saxb3d> <outdir> [--iface <Shader>=<file>]...\n", .{}); std.process.exit(2); }
        var specs: std.ArrayList([]const u8) = .empty;
        var std_shaders: std.ArrayList([]const u8) = .empty;
        var i: usize = 5;
        while (i < argv.len) : (i += 1) {
            if (std.mem.eql(u8, argv[i], "--iface") and i + 1 < argv.len) { i += 1; specs.append(alloc, argv[i]) catch {}; }
            if (std.mem.eql(u8, argv[i], "--std-shader") and i + 1 < argv.len) { i += 1; std_shaders.append(alloc, argv[i]) catch {}; }
        }
        toGltf(&ctx, argv[2], argv[3], argv[4], specs.items, std_shaders.items) catch |e| switch (e) {
            error.ConvertFailed => code = 1,
            else => { ctx.diags.add("CvtBadInput", "unexpected: {s}", .{@errorName(e)}); code = 1; },
        };
    } else { std.debug.print("unknown subcommand '{s}'\n", .{argv[1]}); std.process.exit(2); }
    ctx.ledger.print(init.io);
    if (ctx.diags.count() > 0) { ctx.diags.printAll(); code = 1; }
    std.process.exit(code);
}
