// layout.zig — 段布局规划与名表构建（校验器/写入器/打包器/回读共用一份）。
// 布局律（设计 §7/§8）：头 + 段表之后，载荷按声明序紧密累计，无填充；
// 名表位于文件尾（全部载荷之后），名字各出现一次。

const std = @import("std");
const model = @import("model.zig");
const schema = @import("schema_gen.zig");
const checkmod = @import("check.zig");

pub const SectionPlan = struct {
    name: []const u8,
    kind: schema.SectionKind,
    alignment: u32,
    len: u64,
    offset: u64,
};

pub const Layout = struct {
    plans: std.ArrayList(SectionPlan) = .empty,
    payload_base: u64 = 0,
    payload_end: u64 = 0, // = 名表起点 nametab_off
};

pub fn plan(alloc: std.mem.Allocator, ordered: []const []const u8, lens: *const std.StringHashMap(u64), res: *const checkmod.Resolved) Layout {
    var l = Layout{};
    l.payload_base = @intCast(schema.Sax3dBinHeader_SIZE + ordered.len * schema.Sax3dSectionRec_SIZE);
    var off = l.payload_base;
    for (ordered) |nm| {
        const len = lens.get(nm) orelse 0;
        const kind = res.section_kind.get(nm) orelse .blob;
        const al = res.section_align.get(nm) orelse 1;
        l.plans.append(alloc, .{ .name = nm, .kind = kind, .alignment = al, .len = len, .offset = off }) catch {};
        off += len;
    }
    l.payload_end = off;
    return l;
}

// ---------- 名表 ----------
// 规范构建序：① 段名（按最终段表序）② 声明名（按规范种类序
// shader/mesh/skeleton/image/texture/material/scene/clip，同类内声明序；
// 每个声明随后附其局部名：mesh 的 primitive/morph/attr、skeleton 的 joint、
// scene 的 node（树前序）、clip 的 sampler）。名字在表中恰出现一次：
// 同名字符串二次出现时复用第一次的条目（索引按首次出现）。
pub const NameTable = struct {
    names: std.ArrayList([]const u8) = .empty, // 规范序
    index: std.StringHashMap(u32),             // 名 -> 表索引
    blob: std.ArrayList(u8) = .empty,          // NUL 分隔的表字节
    off_in_tab: std.ArrayList(u32) = .empty,   // 每名在 blob 内的偏移

    pub fn idxOf(self: *const NameTable, name: []const u8) ?u32 { return self.index.get(name); }
    pub fn refText(self: *const NameTable, alloc: std.mem.Allocator, name: []const u8) []const u8 {
        const i = self.index.get(name) orelse return name;
        return std.fmt.allocPrint(alloc, "#{d}", .{i}) catch name;
    }
};

fn ntAdd(nt: *NameTable, alloc: std.mem.Allocator, name: []const u8) void {
    if (nt.index.contains(name)) return;
    const idx: u32 = @intCast(nt.names.items.len);
    nt.index.put(name, idx) catch {};
    nt.names.append(alloc, name) catch {};
}

fn finishTable(nt: *NameTable, alloc: std.mem.Allocator) void {
    var off: u32 = 0;
    for (nt.names.items) |nm| {
        nt.off_in_tab.append(alloc, off) catch {};
        nt.blob.appendSlice(alloc, nm) catch {};
        nt.blob.append(alloc, 0) catch {};
        off += @intCast(nm.len + 1);
    }
}

// 拆分形名表：只有段名（声明活在外部组装文本里）。
pub fn buildSectionNameTable(alloc: std.mem.Allocator, section_names: []const []const u8) NameTable {
    var nt = NameTable{ .index = .init(alloc) };
    for (section_names) |nm| ntAdd(&nt, alloc, nm);
    finishTable(&nt, alloc);
    return nt;
}

// 合并形名表：资产名居首，其后段名（最终段表序），其后全部声明名。
pub fn buildNameTable(alloc: std.mem.Allocator, a: *const model.Asset, section_names: []const []const u8) NameTable {
    var nt = NameTable{ .index = .init(alloc) };
    if (a.name.len > 0) ntAdd(&nt, alloc, a.name);
    for (section_names) |nm| ntAdd(&nt, alloc, nm);
    for (a.shaders.items) |s| ntAdd(&nt, alloc, s.name);
    for (a.meshes.items) |m| {
        ntAdd(&nt, alloc, m.name);
        for (m.prims.items) |pr| ntAdd(&nt, alloc, pr.name);
        for (m.morphs.items) |mo| ntAdd(&nt, alloc, mo.name);
        for (m.channels.items) |ch| { if (ch.custom) ntAdd(&nt, alloc, ch.name); }
    }
    for (a.skeletons.items) |sk| {
        ntAdd(&nt, alloc, sk.name);
        for (sk.joints.items) |j| ntAdd(&nt, alloc, j.name);
    }
    for (a.images.items) |im| ntAdd(&nt, alloc, im.name);
    for (a.textures.items) |t| ntAdd(&nt, alloc, t.name);
    for (a.materials.items) |mt| ntAdd(&nt, alloc, mt.name);
    for (a.scenes.items) |sc| {
        ntAdd(&nt, alloc, sc.name);
        for (sc.roots.items) |*n| ntAddNode(&nt, alloc, n);
    }
    for (a.clips.items) |c| {
        ntAdd(&nt, alloc, c.name);
        for (c.samplers.items) |s| ntAdd(&nt, alloc, s.name);
    }
    finishTable(&nt, alloc);
    return nt;
}

fn ntAddNode(nt: *NameTable, alloc: std.mem.Allocator, n: *const model.NodeDecl) void {
    ntAdd(nt, alloc, n.name);
    for (n.children.items) |*c| ntAddNode(nt, alloc, c);
}

// 从名表 blob 还原名字列表（回读校验用）：按 NUL 切分，去尾随空段。
pub fn splitNameBlob(alloc: std.mem.Allocator, blob: []const u8) std.ArrayList([]const u8) {
    var out: std.ArrayList([]const u8) = .empty;
    var it = std.mem.splitScalar(u8, blob, 0);
    while (it.next()) |part| out.append(alloc, part) catch {};
    if (out.items.len > 0 and out.items[out.items.len - 1].len == 0) _ = out.pop();
    return out;
}
