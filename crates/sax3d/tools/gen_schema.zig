// gen_schema.zig — 把 sax3d.sai（布局唯一真理源）编译为 src/schema_gen.zig。
// 用法: zig run tools/gen_schema.zig -- <sax3d.sai> <schema_gen.zig>
// 解析失败/尺寸不合一律响亮报错退出，绝不产出半成品表。

const std = @import("std");

const Tok = struct { text: []const u8, kind: enum { word, string, punct } };

fn tokenize(alloc: std.mem.Allocator, src: []const u8) ![]Tok {
    var toks: std.ArrayList(Tok) = .empty;
    var i: usize = 0;
    while (i < src.len) {
        const c = src[i];
        if (std.ascii.isWhitespace(c)) { i += 1; continue; }
        if (c == '/' and i + 1 < src.len and src[i + 1] == '/') {
            while (i < src.len and src[i] != '\n') i += 1;
            continue;
        }
        if (c == '"') {
            const s = i + 1;
            i += 1;
            while (i < src.len and src[i] != '"') i += 1;
            if (i >= src.len) return error.UnterminatedString;
            try toks.append(alloc, .{ .text = src[s..i], .kind = .string });
            i += 1;
            continue;
        }
        if (std.ascii.isAlphanumeric(c) or c == '_') {
            const s = i;
            while (i < src.len and (std.ascii.isAlphanumeric(src[i]) or src[i] == '_')) i += 1;
            try toks.append(alloc, .{ .text = src[s..i], .kind = .word });
            continue;
        }
        try toks.append(alloc, .{ .text = src[i .. i + 1], .kind = .punct });
        i += 1;
    }
    return toks.items;
}

const P = struct {
    toks: []Tok,
    pos: usize = 0,
    fn peek(self: *P) ?Tok { return if (self.pos < self.toks.len) self.toks[self.pos] else null; }
    fn next(self: *P) !Tok { const t = self.peek() orelse return error.UnexpectedEof; self.pos += 1; return t; }
    fn expect(self: *P, s: []const u8) !void {
        const t = try self.next();
        if (!std.mem.eql(u8, t.text, s)) { std.debug.print("gen_schema: expected '{s}', got '{s}'\n", .{ s, t.text }); return error.BadSai; }
    }
    fn word(self: *P) ![]const u8 { const t = try self.next(); if (t.kind != .word) return error.BadSai; return t.text; }
    fn num(self: *P) !u64 { const t = try self.next(); return std.fmt.parseInt(u64, t.text, 10) catch return error.BadSai; }
};

fn typeSize(ty: []const u8, count: u64) !u64 {
    if (std.mem.eql(u8, ty, "u8")) return count;
    if (std.mem.eql(u8, ty, "u16")) return 2 * count;
    if (std.mem.eql(u8, ty, "u32")) return 4 * count;
    if (std.mem.eql(u8, ty, "u64")) return 8 * count;
    return error.BadSai;
}

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(alloc);
    if (argv.len < 3) { std.debug.print("usage: gen_schema <sax3d.sai> <out.zig>\n", .{}); return error.Usage; }
    const src = try std.Io.Dir.cwd().readFileAlloc(init.io, argv[1], alloc, .limited(1 << 20));
    var p = P{ .toks = try tokenize(alloc, src) };

    var out: std.Io.Writer.Allocating = .init(alloc);
    const w = &out.writer;
    try w.print("// GENERATED from sax3d.sai by tools/gen_schema.zig — DO NOT EDIT.\n", .{});
    try w.print("// Layout truth lives in sax3d.sai only; regenerate, never hand-sync.\n\n", .{});

    var header_size: u64 = 0;
    var rec_size: u64 = 0;
    while (p.peek()) |t| {
        if (std.mem.eql(u8, t.text, "format")) { _ = try p.next(); _ = try p.word(); try p.expect(";"); }
        else if (std.mem.eql(u8, t.text, "version")) {
            _ = try p.next();
            const maj = try p.num(); const min = try p.num(); try p.expect(";");
            try w.print("pub const VERSION_MAJOR: u16 = {d};\npub const VERSION_MINOR: u16 = {d};\n", .{ maj, min });
        } else if (std.mem.eql(u8, t.text, "magic")) {
            _ = try p.next();
            const which = try p.word();
            const val = (try p.next()).text;
            try p.expect(";");
            if (val.len != 8) { std.debug.print("gen_schema: magic must be 8 bytes, got {d}\n", .{val.len}); return error.BadSai; }
            try w.print("pub const MAGIC_{s} = \"{s}\".*;\n", .{ if (std.mem.eql(u8, which, "split")) "SPLIT" else "PACKED", val });
        } else if (std.mem.eql(u8, t.text, "struct")) {
            _ = try p.next();
            const name = try p.word();
            const declared = try p.num();
            try p.expect("{");
            var off: u64 = 0;
            var fields: std.ArrayList(struct { n: []const u8, o: u64 }) = .empty;
            while (true) {
                const ft = try p.next();
                if (std.mem.eql(u8, ft.text, "}")) break;
                const fname = ft.text;
                try p.expect(":");
                const ty = try p.word();
                var count: u64 = 1;
                if (p.peek() != null and std.mem.eql(u8, p.peek().?.text, "[")) { _ = try p.next(); count = try p.num(); try p.expect("]"); }
                try p.expect(";");
                try fields.append(alloc, .{ .n = fname, .o = off });
                off += try typeSize(ty, count);
            }
            if (off != declared) { std.debug.print("gen_schema: struct {s} fields sum {d} != declared {d}\n", .{ name, off, declared }); return error.BadSai; }
            try w.print("pub const {s}_SIZE: usize = {d};\n", .{ name, declared });
            for (fields.items) |f| try w.print("pub const {s}_{s}_OFF: usize = {d};\n", .{ name, f.n, f.o });
            if (std.mem.eql(u8, name, "Sax3dBinHeader")) header_size = declared;
            if (std.mem.eql(u8, name, "Sax3dSectionRec")) rec_size = declared;
        } else if (std.mem.eql(u8, t.text, "enum")) {
            _ = try p.next();
            const name = try p.word();
            try p.expect("{");
            try w.print("pub const SectionKind = enum(u32) {{\n", .{});
            _ = name;
            while (true) {
                const et = try p.next();
                if (std.mem.eql(u8, et.text, "}")) break;
                try p.expect("=");
                const v = try p.num();
                try p.expect(";");
                try w.print("    {s} = {d},\n", .{ et.text, v });
            }
            try w.print("    pub fn fromU32(v: u32) ?SectionKind {{ return std.enums.fromInt(SectionKind, v); }}\n}};\n", .{});
            try w.print("const std = @import(\"std\");\n", .{});
        } else if (std.mem.eql(u8, t.text, "elem")) {
            _ = try p.next();
            // collected below in second pass marker: emit via placeholder handling
            // (we emit elems immediately as array items into a buffered list)
            const nm = try p.word();
            const sz = try p.num();
            const al = try p.num();
            try p.expect(";");
            try elems.append(alloc, .{ .n = nm, .s = sz, .a = al });
        } else { std.debug.print("gen_schema: unknown directive '{s}'\n", .{t.text}); return error.BadSai; }
    }
    if (header_size == 0 or rec_size == 0) { std.debug.print("gen_schema: header/section-rec structs missing\n", .{}); return error.BadSai; }

    // elems are emitted at the end (they were collected during the pass)
    try w.print("\npub const ElemType = struct {{ name: []const u8, size: u64, alignment: u32 }};\n", .{});
    try w.print("pub const ELEM_TYPES = [_]ElemType{{\n", .{});
    for (elems.items) |e| try w.print("    .{{ .name = \"{s}\", .size = {d}, .alignment = {d} }},\n", .{ e.n, e.s, e.a });
    try w.print("}};\n", .{});
    try w.print("pub fn elemType(name: []const u8) ?ElemType {{ for (ELEM_TYPES) |e| {{ if (std.mem.eql(u8, e.name, name)) return e; }} return null; }}\n", .{});

    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = argv[2], .data = out.written() });
    std.debug.print("gen_schema: wrote {s} (header {d}B, rec {d}B, {d} elem types)\n", .{ argv[2], header_size, rec_size, elems.items.len });
}

var elems: std.ArrayList(struct { n: []const u8, s: u64, a: u64 }) = .empty;
