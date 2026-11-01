// readback.zig — SAX3D 回读校验器（测试专用，NOT a shipped loader）。
// 用户裁定：加载属上层，std 与工具链均不交付加载器；本工具仅在验收中
// 证明二进制可被独立回读核对：
//   readback split  <asset.sax3d> <file.saxb3d> [--iface <Shader>=<file>]...
//   readback packed <file.sax3dp> [--iface <Shader>=<file>]...
// 两模式都打印规范等价摘要（digest-* 行）：段（名/kind/长/sha256）与
// 声明（种类/索引/名），供验收脚本逐行对拍两形等价。

const std = @import("std");
const lib = @import("sax3d");
const model = lib.model;
const parse = lib.parse;
const ifacemod = lib.ifacemod;
const checkmod = lib.checkmod;
const layout = lib.layout;
const binio = lib.binio;
const schema = lib.schema;

const G = struct {
    alloc: std.mem.Allocator,
    io: std.Io,
    diags: model.Diags,
    ifaces: std.StringHashMap(ifacemod.Iface),
};

fn sha256Hex(alloc: std.mem.Allocator, data: []const u8) []const u8 {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(data, &digest, .{});
    return std.fmt.allocPrint(alloc, "{x}", .{&digest}) catch "?";
}

fn outLine(g: *G, comptime fmt: []const u8, args: anytype) void {
    const line = std.fmt.allocPrint(g.alloc, fmt ++ "\n", args) catch return;
    std.Io.File.stdout().writeStreamingAll(g.io, line) catch {};
}

fn digestDecls(g: *G, a: *const model.Asset) void {
    for (a.shaders.items, 0..) |s, i| outLine(g, "digest-decl shader {d} {s}", .{ i, s.name });
    for (a.meshes.items, 0..) |m, i| outLine(g, "digest-decl mesh {d} {s}", .{ i, m.name });
    for (a.skeletons.items, 0..) |s, i| outLine(g, "digest-decl skeleton {d} {s}", .{ i, s.name });
    for (a.images.items, 0..) |s, i| outLine(g, "digest-decl image {d} {s}", .{ i, s.name });
    for (a.textures.items, 0..) |s, i| outLine(g, "digest-decl texture {d} {s}", .{ i, s.name });
    for (a.materials.items, 0..) |m, i| outLine(g, "digest-decl material {d} {s}", .{ i, m.name });
    const nodes = checkmod.collectNodes(g.alloc, a);
    for (nodes.items, 0..) |ni, i| outLine(g, "digest-decl node {d} {s}", .{ i, ni.node.name });
    for (a.clips.items, 0..) |c, i| outLine(g, "digest-decl clip {d} {s}", .{ i, c.name });
}

fn loadIfaces(g: *G, specs: []const []const u8) void {
    for (specs) |sp| {
        const eq = std.mem.indexOfScalar(u8, sp, '=') orelse continue;
        const src = std.Io.Dir.cwd().readFileAlloc(g.io, sp[eq + 1 ..], g.alloc, .limited(1 << 24)) catch continue;
        g.ifaces.put(sp[0..eq], ifacemod.parseIface(g.alloc, src, &g.diags, sp[0..eq])) catch {};
    }
}

fn verdict(g: *G) u8 {
    if (g.diags.count() > 0) {
        g.diags.printAll();
        std.debug.print("READBACK FAILED: {d} error(s)\n", .{g.diags.count()});
        return 1;
    }
    std.debug.print("READBACK OK\n", .{});
    return 0;
}

// 通用段表核对：plans（期望）对 recs（实际）逐项比名/kind/偏移/长/对齐/name_off。
fn verifySections(g: *G, bytes: []const u8, hdr: binio.Header, lay: *const layout.Layout, nt: *const layout.NameTable) void {
    if (hdr.section_count != lay.plans.items.len) {
        g.diags.add("Sax3dSectionMismatch", "header section_count {d} != expected {d}", .{ hdr.section_count, lay.plans.items.len });
        return;
    }
    if (hdr.nametab_off != lay.payload_end)
        g.diags.add("Sax3dNameTableMismatch", "header nametab_off {d} != payload end {d}", .{ hdr.nametab_off, lay.payload_end });
    if (hdr.nametab_len != nt.blob.items.len)
        g.diags.add("Sax3dNameTableMismatch", "header nametab_len {d} != canonical table {d}B", .{ hdr.nametab_len, nt.blob.items.len });
    const blob = binio.nameBlob(bytes, hdr, &g.diags) orelse return;
    if (!std.mem.eql(u8, blob, nt.blob.items))
        g.diags.add("Sax3dNameTableMismatch", "name table bytes differ from canonical rebuild", .{});
    for (lay.plans.items, 0..) |p, i| {
        const rec = binio.readRec(bytes, i);
        const nm = binio.nameAt(bytes, hdr, rec.name_off) orelse {
            g.diags.add("Sax3dNameTableMismatch", "section {d}: name_off {d} unresolvable", .{ i, rec.name_off });
            continue;
        };
        if (!std.mem.eql(u8, nm, p.name))
            g.diags.add("Sax3dSectionMismatch", "section {d}: name '{s}' != expected '{s}'", .{ i, nm, p.name });
        if (rec.kind != @intFromEnum(p.kind))
            g.diags.add("Sax3dSectionMismatch", "section '{s}': kind {d} != expected {d} ({s})", .{ p.name, rec.kind, @intFromEnum(p.kind), @tagName(p.kind) });
        if (rec.offset != p.offset or rec.len != p.len)
            g.diags.add("Sax3dSectionMismatch", "section '{s}': (offset {d}, len {d}) != planned ({d}, {d})", .{ p.name, rec.offset, rec.len, p.offset, p.len });
        if (rec.offset + rec.len > bytes.len)
            g.diags.add("Sax3dTruncatedFile", "section '{s}' overruns file ({d}B)", .{ p.name, bytes.len });
        const want_off = lay.payload_end + (nt.off_in_tab.items[nt.index.get(p.name).?]);
        if (rec.name_off != want_off)
            g.diags.add("Sax3dNameTableMismatch", "section '{s}': name_off {d} != canonical {d}", .{ p.name, rec.name_off, want_off });
    }
}

fn modeSplit(g: *G, text_path: []const u8, bin_path: []const u8) u8 {
    const src = std.Io.Dir.cwd().readFileAlloc(g.io, text_path, g.alloc, .limited(1 << 24)) catch |e| {
        g.diags.add("Sax3dIoError", "cannot read '{s}': {s}", .{ text_path, @errorName(e) });
        return verdict(g);
    };
    var asset = parse.parse(g.alloc, src, .authoring, &.{}, &g.diags) catch { return verdict(g); };
    const res = checkmod.check(g.alloc, &asset, &g.ifaces, &g.diags);
    if (g.diags.count() > 0) return verdict(g);
    const bytes = std.Io.Dir.cwd().readFileAlloc(g.io, bin_path, g.alloc, .limited(1 << 28)) catch |e| {
        g.diags.add("Sax3dIoError", "cannot read '{s}': {s}", .{ bin_path, @errorName(e) });
        return verdict(g);
    };
    const hdr = binio.parseHeader(bytes, &g.diags) orelse return verdict(g);
    if (!binio.tableFits(bytes, hdr)) {
        g.diags.add("Sax3dTruncatedFile", "file is {d}B, section table of {d} records does not fit", .{ bytes.len, hdr.section_count });
        return verdict(g);
    }
    if (hdr.form != .split) {
        g.diags.add("Sax3dBadMagic", "'{s}' is not a split-form binary", .{bin_path});
        return verdict(g);
    }
    var order: std.ArrayList([]const u8) = .empty;
    var lens: std.StringHashMap(u64) = .init(g.alloc);
    if (asset.binary) |b| { for (b.sections.items) |s| { order.append(g.alloc, s.name) catch {}; lens.put(s.name, s.len) catch {}; } }
    const lay = layout.plan(g.alloc, order.items, &lens, &res);
    const nt = layout.buildSectionNameTable(g.alloc, order.items);
    verifySections(g, bytes, hdr, &lay, &nt);
    if (g.diags.count() > 0) return verdict(g);
    for (lay.plans.items) |p|
        outLine(g, "digest-section {s} {s} {d} {s}", .{ p.name, @tagName(p.kind), p.len, sha256Hex(g.alloc, bytes[@intCast(p.offset)..@intCast(p.offset + p.len)]) });
    // 路径源图像在拆分形是外部文件：以伪段进入摘要（kind 与合并形内嵌段一致），
    // 使两形摘要可逐行对拍。
    const text_dir = std.fs.path.dirname(text_path) orelse ".";
    for (asset.images.items) |im| {
        if (im.source_kind == .path) {
            const full = std.fmt.allocPrint(g.alloc, "{s}/{s}", .{ text_dir, im.source }) catch unreachable;
            const data = std.Io.Dir.cwd().readFileAlloc(g.io, full, g.alloc, .limited(1 << 28)) catch |e| {
                g.diags.add("Sax3dIoError", "cannot read image file '{s}': {s}", .{ full, @errorName(e) });
                return verdict(g);
            };
            const kind: schema.SectionKind = if (std.mem.startsWith(u8, im.format, "raw-")) .image_raw else .blob;
            outLine(g, "digest-section {s} {s} {d} {s}", .{ im.name, @tagName(kind), data.len, sha256Hex(g.alloc, data) });
        }
    }
    digestDecls(g, &asset);
    return verdict(g);
}

fn modePacked(g: *G, bin_path: []const u8) u8 {
    const bytes = std.Io.Dir.cwd().readFileAlloc(g.io, bin_path, g.alloc, .limited(1 << 28)) catch |e| {
        g.diags.add("Sax3dIoError", "cannot read '{s}': {s}", .{ bin_path, @errorName(e) });
        return verdict(g);
    };
    const hdr = binio.parseHeader(bytes, &g.diags) orelse return verdict(g);
    if (!binio.tableFits(bytes, hdr)) {
        g.diags.add("Sax3dTruncatedFile", "file is {d}B, section table of {d} records does not fit", .{ bytes.len, hdr.section_count });
        return verdict(g);
    }
    if (hdr.form != .merged) {
        g.diags.add("Sax3dBadMagic", "'{s}' is not a packed-form binary", .{bin_path});
        return verdict(g);
    }
    const blob = binio.nameBlob(bytes, hdr, &g.diags) orelse return verdict(g);
    const names = layout.splitNameBlob(g.alloc, blob);
    // 段表 -> 名字/长度/种类映射；找组装段。
    var rec_names: std.ArrayList([]const u8) = .empty;
    var rec_lens: std.StringHashMap(u64) = .init(g.alloc);
    var asm_bytes: ?[]const u8 = null;
    var i: usize = 0;
    while (i < hdr.section_count) : (i += 1) {
        const rec = binio.readRec(bytes, i);
        const nm = binio.nameAt(bytes, hdr, rec.name_off) orelse {
            g.diags.add("Sax3dNameTableMismatch", "section {d}: name_off {d} unresolvable", .{ i, rec.name_off });
            return verdict(g);
        };
        rec_names.append(g.alloc, nm) catch {};
        rec_lens.put(nm, rec.len) catch {};
        if (rec.kind == @intFromEnum(schema.SectionKind.assembly)) {
            if (rec.offset + rec.len > bytes.len) {
                g.diags.add("Sax3dTruncatedFile", "assembly section overruns file", .{});
                return verdict(g);
            }
            asm_bytes = bytes[@intCast(rec.offset)..@intCast(rec.offset + rec.len)];
        }
    }
    const asm_text = asm_bytes orelse {
        g.diags.add("Sax3dSectionMismatch", "packed file has no assembly section", .{});
        return verdict(g);
    };
    // 解编译形组装 -> AST（名字经名表还原）。
    var asset = parse.parse(g.alloc, asm_text, .compiled, names.items, &g.diags) catch { return verdict(g); };
    // 段长由段表回填（二进制是长度的在场真理），并核对组装所列段与段表一致。
    if (asset.binary) |*b| {
        for (b.sections.items) |*s| {
            const l = rec_lens.get(s.name) orelse {
                g.diags.add("Sax3dSectionMismatch", "assembly lists section '{s}' absent from section table", .{s.name});
                return verdict(g);
            };
            s.len = l;
        }
        for (rec_names.items) |rn| {
            if (std.mem.eql(u8, rn, "assembly")) continue;
            var listed = false;
            for (b.sections.items) |s| { if (std.mem.eql(u8, s.name, rn)) listed = true; }
            if (!listed) {
                g.diags.add("Sax3dSectionMismatch", "section table carries '{s}' not listed in assembly", .{rn});
                return verdict(g);
            }
        }
    }
    const res0 = checkmod.check(g.alloc, &asset, &g.ifaces, &g.diags);
    if (g.diags.count() > 0) return verdict(g);
    // 按最终段表序重建 名表/布局 并全量核对。
    var res = res0;
    res.section_kind.put("assembly", .assembly) catch {};
    res.section_align.put("assembly", 1) catch {};
    const nt = layout.buildNameTable(g.alloc, &asset, rec_names.items);
    const lay = layout.plan(g.alloc, rec_names.items, &rec_lens, &res);
    verifySections(g, bytes, hdr, &lay, &nt);
    if (g.diags.count() > 0) return verdict(g);
    for (lay.plans.items) |p| {
        if (std.mem.eql(u8, p.name, "assembly")) continue;
        outLine(g, "digest-section {s} {s} {d} {s}", .{ p.name, @tagName(p.kind), p.len, sha256Hex(g.alloc, bytes[@intCast(p.offset)..@intCast(p.offset + p.len)]) });
    }
    digestDecls(g, &asset);
    return verdict(g);
}

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    var g = G{ .alloc = alloc, .io = init.io, .diags = model.Diags.init(alloc), .ifaces = .init(alloc) };
    const argv = try init.minimal.args.toSlice(alloc);
    if (argv.len < 3) {
        std.debug.print("usage: readback <split <asset.sax3d> <file.saxb3d>|packed <file.sax3dp>> [--iface <Shader>=<file>]...\n", .{});
        std.process.exit(2);
    }
    var specs: std.ArrayList([]const u8) = .empty;
    var i: usize = 2;
    while (i < argv.len) : (i += 1) {
        if (std.mem.eql(u8, argv[i], "--iface") and i + 1 < argv.len) { i += 1; specs.append(alloc, argv[i]) catch {}; }
    }
    loadIfaces(&g, specs.items);
    var code: u8 = 2;
    if (std.mem.eql(u8, argv[1], "split") and argv.len >= 4) code = modeSplit(&g, argv[2], argv[3])
    else if (std.mem.eql(u8, argv[1], "packed")) code = modePacked(&g, argv[2])
    else { std.debug.print("bad readback invocation\n", .{}); std.process.exit(2); }
    std.process.exit(code);
}
