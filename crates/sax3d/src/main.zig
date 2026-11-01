// sax3dc — SAX3D 工具链：裁判校验器 + 拆分形写入器 + 合并形打包器。
//   sax3dc check <asset.sax3d> [--iface <Shader>=<file>]...
//   sax3dc build <asset.sax3d> --payload-dir <dir> [--out <file.saxb3d>] [--iface ...]
//   sax3dc pack  <asset.sax3d> --bin <file.saxb3d> [--out <file.sax3dp>] [--iface ...]
// 校验不过一律具名诊断 + 退出码 1，绝不带病产出文件。

const std = @import("std");
const model = @import("model.zig");
const parse = @import("parse.zig");
const ifacemod = @import("iface.zig");
const checkmod = @import("check.zig");
const layout = @import("layout.zig");
const binio = @import("binio.zig");
const packform = @import("packform.zig");
const schema = @import("schema_gen.zig");

const G = struct {
    alloc: std.mem.Allocator,
    io: std.Io,
    diags: model.Diags,
    ifaces: std.StringHashMap(ifacemod.Iface),
};

fn readFile(g: *G, path: []const u8) ?[]u8 {
    return std.Io.Dir.cwd().readFileAlloc(g.io, path, g.alloc, .limited(1 << 28)) catch |e| {
        g.diags.add("Sax3dIoError", "cannot read '{s}': {s}", .{ path, @errorName(e) });
        return null;
    };
}

fn loadIfaces(g: *G, specs: []const []const u8) void {
    for (specs) |sp| {
        const eq = std.mem.indexOfScalar(u8, sp, '=') orelse {
            g.diags.add("Sax3dIoError", "--iface expects <Shader>=<file>, got '{s}'", .{sp});
            continue;
        };
        const src = readFile(g, sp[eq + 1 ..]) orelse continue;
        const f = ifacemod.parseIface(g.alloc, src, &g.diags, sp[0..eq]);
        g.ifaces.put(sp[0..eq], f) catch {};
    }
}

fn parseAndCheck(g: *G, path: []const u8) ?struct { asset: model.Asset, res: checkmod.Resolved } {
    const src = readFile(g, path) orelse return null;
    var asset = parse.parse(g.alloc, src, .authoring, &.{}, &g.diags) catch |e| {
        g.diags.add("Sax3dIoError", "parse of '{s}' failed hard: {s}", .{ path, @errorName(e) });
        return null;
    };
    const res = checkmod.check(g.alloc, &asset, &g.ifaces, &g.diags);
    return .{ .asset = asset, .res = res };
}

fn sectionLens(g: *G, a: *const model.Asset) std.StringHashMap(u64) {
    var m: std.StringHashMap(u64) = .init(g.alloc);
    if (a.binary) |b| { for (b.sections.items) |s| m.put(s.name, s.len) catch {}; }
    return m;
}

fn sectionOrder(g: *G, a: *const model.Asset) std.ArrayList([]const u8) {
    var out: std.ArrayList([]const u8) = .empty;
    if (a.binary) |b| { for (b.sections.items) |s| out.append(g.alloc, s.name) catch {}; }
    return out;
}

fn printManifest(g: *G, a: *const model.Asset, lay: *const layout.Layout, nametab_len: usize) void {
    std.debug.print("VALIDATION OK\n== sections ==\n", .{});
    for (lay.plans.items, 0..) |p, i|
        std.debug.print("  [{d}] {s}: kind {s}, offset {d}, len {d}\n", .{ i, p.name, @tagName(p.kind), p.offset, p.len });
    std.debug.print("  payload end {d}, name table {d}B, file size {d}B\n== resolved names ==\n", .{ lay.payload_end, nametab_len, lay.payload_end + nametab_len });
    for (a.shaders.items, 0..) |s, i| std.debug.print("  shader[{d}] {s}\n", .{ i, s.name });
    for (a.meshes.items, 0..) |m, i| std.debug.print("  mesh[{d}] {s}\n", .{ i, m.name });
    for (a.skeletons.items, 0..) |s, i| std.debug.print("  skeleton[{d}] {s}\n", .{ i, s.name });
    for (a.images.items, 0..) |s, i| std.debug.print("  image[{d}] {s}\n", .{ i, s.name });
    for (a.textures.items, 0..) |s, i| std.debug.print("  texture[{d}] {s}\n", .{ i, s.name });
    for (a.materials.items, 0..) |m, i| std.debug.print("  material[{d}] {s} (shader {s})\n", .{ i, m.name, m.shader });
    const nodes = checkmod.collectNodes(g.alloc, a);
    for (nodes.items, 0..) |ni, i| std.debug.print("  node[{d}] {s}\n", .{ i, ni.node.name });
    for (a.clips.items, 0..) |c, i| std.debug.print("  clip[{d}] {s} ({d} channels)\n", .{ i, c.name, c.channels.items.len });
}

fn verdict(g: *G) u8 {
    if (g.diags.count() > 0) {
        g.diags.printAll();
        std.debug.print("VALIDATION FAILED: {d} error(s)\n", .{g.diags.count()});
        return 1;
    }
    return 0;
}

fn cmdCheck(g: *G, path: []const u8) u8 {
    const r = parseAndCheck(g, path) orelse return verdict(g);
    if (verdict(g) != 0) return 1;
    const order = sectionOrder(g, &r.asset);
    const lens = sectionLens(g, &r.asset);
    const lay = layout.plan(g.alloc, order.items, &lens, &r.res);
    const nt = layout.buildSectionNameTable(g.alloc, order.items);
    printManifest(g, &r.asset, &lay, nt.blob.items.len);
    return 0;
}

fn cmdBuild(g: *G, path: []const u8, payload_dir: []const u8, out_path: ?[]const u8) u8 {
    const r = parseAndCheck(g, path) orelse return verdict(g);
    if (g.diags.count() > 0) return verdict(g);
    const a = &r.asset;
    const b = a.binary orelse {
        g.diags.add("Sax3dInvalidValue", "asset has no binary block; nothing to write", .{});
        return verdict(g);
    };
    // 载荷：<payload-dir>/<section>.bin，长度必须与声明逐字相等。
    var payloads: std.ArrayList([]const u8) = .empty;
    for (b.sections.items) |s| {
        const p = std.fmt.allocPrint(g.alloc, "{s}/{s}.bin", .{ payload_dir, s.name }) catch unreachable;
        const data = std.Io.Dir.cwd().readFileAlloc(g.io, p, g.alloc, .limited(1 << 28)) catch |e| {
            g.diags.add("Sax3dPayloadMissing", "section '{s}': payload file '{s}' unreadable ({s})", .{ s.name, p, @errorName(e) });
            payloads.append(g.alloc, &.{}) catch {};
            continue;
        };
        if (data.len != s.len)
            g.diags.add("Sax3dPayloadLengthMismatch", "section '{s}': payload file is {d}B, declaration says {d}B", .{ s.name, data.len, s.len });
        payloads.append(g.alloc, data) catch {};
    }
    if (g.diags.count() > 0) return verdict(g);
    // 数据级检查：动画时间轴单调不减（f32 段）。
    for (b.sections.items, 0..) |s, i| {
        if (r.res.section_kind.get(s.name) == .anim_input) {
            const data = payloads.items[i];
            var prev: f32 = -std.math.inf(f32);
            var j: usize = 0;
            while (j + 4 <= data.len) : (j += 4) {
                const v = std.mem.readInt(u32, data[j..][0..4], .little);
                const f: f32 = @bitCast(v);
                if (f < prev) {
                    g.diags.add("Sax3dAnimInputNotMonotonic", "section '{s}': time axis decreases at element {d}", .{ s.name, j / 4 });
                    break;
                }
                prev = f;
            }
        }
    }
    if (g.diags.count() > 0) return verdict(g);
    const order = sectionOrder(g, a);
    const lens = sectionLens(g, a);
    const lay = layout.plan(g.alloc, order.items, &lens, &r.res);
    const nt = layout.buildSectionNameTable(g.alloc, order.items);
    const bytes = binio.assemble(g.alloc, .split, &lay, payloads.items, &nt) catch |e| {
        g.diags.add("Sax3dIoError", "assemble failed: {s}", .{@errorName(e)});
        return verdict(g);
    };
    const outp = out_path orelse b.file;
    std.Io.Dir.cwd().writeFile(g.io, .{ .sub_path = outp, .data = bytes }) catch |e| {
        g.diags.add("Sax3dIoError", "cannot write '{s}': {s}", .{ outp, @errorName(e) });
        return verdict(g);
    };
    printManifest(g, a, &lay, nt.blob.items.len);
    std.debug.print("WROTE {s} ({d}B)\n", .{ outp, bytes.len });
    return 0;
}

fn cmdPack(g: *G, path: []const u8, bin_path: []const u8, out_path: ?[]const u8) u8 {
    const r = parseAndCheck(g, path) orelse return verdict(g);
    if (g.diags.count() > 0) return verdict(g);
    var a = r.asset;
    // 读拆分形二进制，核对与文本声明一致（段名集 + 长度）。
    const bin_bytes = readFile(g, bin_path) orelse return verdict(g);
    const hdr = binio.parseHeader(bin_bytes, &g.diags) orelse return verdict(g);
    if (!binio.tableFits(bin_bytes, hdr)) {
        g.diags.add("Sax3dTruncatedFile", "'{s}' is {d}B, section table of {d} records does not fit", .{ bin_path, bin_bytes.len, hdr.section_count });
        return verdict(g);
    }
    if (hdr.form != .split) {
        g.diags.add("Sax3dBadMagic", "pack input '{s}' is not a split-form binary", .{bin_path});
        return verdict(g);
    }
    var split_payloads: std.StringHashMap([]const u8) = .init(g.alloc);
    {
        const blob = binio.nameBlob(bin_bytes, hdr, &g.diags) orelse return verdict(g);
        _ = blob;
        var i: usize = 0;
        while (i < hdr.section_count) : (i += 1) {
            const rec = binio.readRec(bin_bytes, i);
            const nm = binio.nameAt(bin_bytes, hdr, rec.name_off) orelse {
                g.diags.add("Sax3dNameTableMismatch", "section {d}: name_off {d} does not resolve in name table", .{ i, rec.name_off });
                return verdict(g);
            };
            if (rec.offset + rec.len > bin_bytes.len) {
                g.diags.add("Sax3dTruncatedFile", "section '{s}' overruns file", .{nm});
                return verdict(g);
            }
            split_payloads.put(nm, bin_bytes[@intCast(rec.offset)..@intCast(rec.offset + rec.len)]) catch {};
        }
    }
    if (a.binary) |b| {
        for (b.sections.items) |s| {
            const pl = split_payloads.get(s.name) orelse {
                g.diags.add("Sax3dSectionMismatch", "split binary lacks section '{s}' declared in text", .{s.name});
                return verdict(g);
            };
            if (pl.len != s.len) {
                g.diags.add("Sax3dSectionMismatch", "section '{s}': text declares {d}B, split binary carries {d}B", .{ s.name, s.len, pl.len });
                return verdict(g);
            }
        }
        // 反向亦然：二进制里多出的段不许被静默丢弃。
        var kit = split_payloads.keyIterator();
        while (kit.next()) |k| {
            var declared = false;
            for (b.sections.items) |s| { if (std.mem.eql(u8, s.name, k.*)) declared = true; }
            if (!declared) {
                g.diags.add("Sax3dSectionMismatch", "split binary carries section '{s}' not declared in text; refusing to drop it silently", .{k.*});
                return verdict(g);
            }
        }
    }
    // 变换：路径源图像内嵌为段（段名 = 图像名；与既有段名冲突响亮报错）。
    const text_dir = std.fs.path.dirname(path) orelse ".";
    var embedded: std.ArrayList(model.SectionDecl) = .empty;
    var embedded_payloads: std.StringHashMap([]const u8) = .init(g.alloc);
    for (a.images.items) |*im| {
        if (im.source_kind == .path) {
            if (split_payloads.contains(im.name) or (a.binary != null and blk: {
                for (a.binary.?.sections.items) |s| { if (std.mem.eql(u8, s.name, im.name)) break :blk true; }
                break :blk false;
            })) {
                g.diags.add("Sax3dPackNameCollision", "image '{s}': embedded section name collides with an existing section", .{im.name});
                return verdict(g);
            }
            const full = std.fmt.allocPrint(g.alloc, "{s}/{s}", .{ text_dir, im.source }) catch unreachable;
            const data = readFile(g, full) orelse return verdict(g);
            embedded.append(g.alloc, .{ .name = im.name, .len = data.len }) catch {};
            embedded_payloads.put(im.name, data) catch {};
            im.source_kind = .section;
            im.source = im.name;
        }
    }
    if (a.binary == null) a.binary = model.BinaryDecl{ .file = "" };
    for (embedded.items) |s| a.binary.?.sections.append(g.alloc, s) catch {};
    // 变换后复检（段 kind 重新指派，含内嵌图像）。
    var diags2 = model.Diags.init(g.alloc);
    const res2 = checkmod.check(g.alloc, &a, &g.ifaces, &diags2);
    if (diags2.count() > 0) {
        diags2.printAll();
        std.debug.print("VALIDATION FAILED (post-transform): {d} error(s)\n", .{diags2.count()});
        return 1;
    }
    // 最终段序：组装段居尾。名表按最终段序构建。
    var order: std.ArrayList([]const u8) = .empty;
    for (a.binary.?.sections.items) |s| order.append(g.alloc, s.name) catch {};
    order.append(g.alloc, "assembly") catch {};
    const nt = layout.buildNameTable(g.alloc, &a, order.items);
    const compiled = packform.emit(g.alloc, &a, &nt) catch |e| {
        g.diags.add("Sax3dIoError", "compiled emission failed: {s}", .{@errorName(e)});
        return verdict(g);
    };
    var lens = sectionLens(g, &a);
    lens.put("assembly", compiled.len) catch {};
    var res3 = res2;
    res3.section_kind.put("assembly", .assembly) catch {};
    res3.section_align.put("assembly", 1) catch {};
    const lay = layout.plan(g.alloc, order.items, &lens, &res3);
    var payloads: std.ArrayList([]const u8) = .empty;
    for (order.items) |nm| {
        if (std.mem.eql(u8, nm, "assembly")) payloads.append(g.alloc, compiled) catch {}
        else if (embedded_payloads.get(nm)) |d| payloads.append(g.alloc, d) catch {}
        else payloads.append(g.alloc, split_payloads.get(nm).?) catch {};
    }
    const bytes = binio.assemble(g.alloc, .merged, &lay, payloads.items, &nt) catch |e| {
        g.diags.add("Sax3dIoError", "assemble failed: {s}", .{@errorName(e)});
        return verdict(g);
    };
    const outp = out_path orelse "asset.sax3dp";
    std.Io.Dir.cwd().writeFile(g.io, .{ .sub_path = outp, .data = bytes }) catch |e| {
        g.diags.add("Sax3dIoError", "cannot write '{s}': {s}", .{ outp, @errorName(e) });
        return verdict(g);
    };
    printManifest(g, &a, &lay, nt.blob.items.len);
    std.debug.print("WROTE {s} ({d}B, packed)\n", .{ outp, bytes.len });
    return 0;
}

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    var g = G{ .alloc = alloc, .io = init.io, .diags = model.Diags.init(alloc), .ifaces = .init(alloc) };
    const argv = try init.minimal.args.toSlice(alloc);
    if (argv.len < 3) {
        std.debug.print("usage: sax3dc <check|build|pack> <asset.sax3d> [--iface <Shader>=<file>] [--payload-dir <dir>] [--bin <file>] [--out <file>]\n", .{});
        std.process.exit(2);
    }
    const cmd = argv[1];
    const path = argv[2];
    var iface_specs: std.ArrayList([]const u8) = .empty;
    var payload_dir: []const u8 = "";
    var bin_path: []const u8 = "";
    var out_path: ?[]const u8 = null;
    var i: usize = 3;
    while (i < argv.len) : (i += 1) {
        if (std.mem.eql(u8, argv[i], "--iface") and i + 1 < argv.len) { i += 1; iface_specs.append(alloc, argv[i]) catch {}; }
        else if (std.mem.eql(u8, argv[i], "--payload-dir") and i + 1 < argv.len) { i += 1; payload_dir = argv[i]; }
        else if (std.mem.eql(u8, argv[i], "--bin") and i + 1 < argv.len) { i += 1; bin_path = argv[i]; }
        else if (std.mem.eql(u8, argv[i], "--out") and i + 1 < argv.len) { i += 1; out_path = argv[i]; }
        else { std.debug.print("unknown arg '{s}'\n", .{argv[i]}); std.process.exit(2); }
    }
    loadIfaces(&g, iface_specs.items);
    if (g.diags.count() > 0) std.process.exit(verdict(&g));
    var code: u8 = 2;
    if (std.mem.eql(u8, cmd, "check")) code = cmdCheck(&g, path)
    else if (std.mem.eql(u8, cmd, "build")) code = cmdBuild(&g, path, payload_dir, out_path)
    else if (std.mem.eql(u8, cmd, "pack")) code = cmdPack(&g, path, bin_path, out_path)
    else { std.debug.print("unknown subcommand '{s}'\n", .{cmd}); std.process.exit(2); }
    std.process.exit(code);
}
