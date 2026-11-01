// binio.zig — SAX3D 二进制读写基元（布局全部取自 schema_gen，禁止手算）。
// 两形共用头结构，魔数分形。写入器（拆分形/合并形）与回读校验器共用本模块。

const std = @import("std");
const schema = @import("schema_gen.zig");
const layout = @import("layout.zig");
const model = @import("model.zig");

pub const Form = enum { split, merged };

pub fn putU16(buf: []u8, off: usize, v: u16) void { std.mem.writeInt(u16, buf[off..][0..2], v, .little); }
pub fn putU32(buf: []u8, off: usize, v: u32) void { std.mem.writeInt(u32, buf[off..][0..4], v, .little); }
pub fn putU64(buf: []u8, off: usize, v: u64) void { std.mem.writeInt(u64, buf[off..][0..8], v, .little); }
pub fn getU16(buf: []const u8, off: usize) u16 { return std.mem.readInt(u16, buf[off..][0..2], .little); }
pub fn getU32(buf: []const u8, off: usize) u32 { return std.mem.readInt(u32, buf[off..][0..4], .little); }
pub fn getU64(buf: []const u8, off: usize) u64 { return std.mem.readInt(u64, buf[off..][0..8], .little); }

// 组装一份二进制：plans 已含 offset/len/kind/align；payloads 与 plans 同序；
// nt 为名表（plans 中段名必须都在表内）。返回完整文件字节。
pub fn assemble(alloc: std.mem.Allocator, form: Form, lay: *const layout.Layout, payloads: []const []const u8, nt: *const layout.NameTable) ![]u8 {
    const n = lay.plans.items.len;
    const total = lay.payload_end + nt.blob.items.len;
    var buf = try alloc.alloc(u8, @intCast(total));
    @memset(buf, 0);
    const magic = if (form == .split) schema.MAGIC_SPLIT else schema.MAGIC_PACKED;
    @memcpy(buf[schema.Sax3dBinHeader_magic_OFF..][0..8], &magic);
    putU16(buf, schema.Sax3dBinHeader_version_major_OFF, schema.VERSION_MAJOR);
    putU16(buf, schema.Sax3dBinHeader_version_minor_OFF, schema.VERSION_MINOR);
    putU32(buf, schema.Sax3dBinHeader_section_count_OFF, @intCast(n));
    putU32(buf, schema.Sax3dBinHeader_flags_OFF, 0);
    putU32(buf, schema.Sax3dBinHeader_nametab_off_OFF, @intCast(lay.payload_end));
    putU32(buf, schema.Sax3dBinHeader_nametab_len_OFF, @intCast(nt.blob.items.len));
    for (lay.plans.items, 0..) |p, i| {
        const base = schema.Sax3dBinHeader_SIZE + i * schema.Sax3dSectionRec_SIZE;
        const name_idx = nt.index.get(p.name) orelse return error.SectionNameNotInTable;
        const name_abs: u64 = lay.payload_end + nt.off_in_tab.items[name_idx];
        putU32(buf, base + schema.Sax3dSectionRec_name_off_OFF, @intCast(name_abs));
        putU32(buf, base + schema.Sax3dSectionRec_kind_OFF, @intFromEnum(p.kind));
        putU64(buf, base + schema.Sax3dSectionRec_offset_OFF, p.offset);
        putU64(buf, base + schema.Sax3dSectionRec_len_OFF, p.len);
        putU32(buf, base + schema.Sax3dSectionRec_align_OFF, p.alignment);
        @memcpy(buf[@intCast(p.offset)..][0..@intCast(p.len)], payloads[i]);
    }
    @memcpy(buf[@intCast(lay.payload_end)..][0..nt.blob.items.len], nt.blob.items);
    return buf;
}

pub const Header = struct {
    form: Form,
    section_count: u32,
    nametab_off: u32,
    nametab_len: u32,
};

pub const Rec = struct { name_off: u32, kind: u32, offset: u64, len: u64, alignment: u32 };

// 解头：具名诊断（二进制面诊断码与文本面分列，见 SPEC）。
pub fn parseHeader(bytes: []const u8, diags: *model.Diags) ?Header {
    if (bytes.len < schema.Sax3dBinHeader_SIZE) {
        diags.add("Sax3dTruncatedFile", "file is {d}B, smaller than the 32B header", .{bytes.len});
        return null;
    }
    const magic = bytes[schema.Sax3dBinHeader_magic_OFF..][0..8];
    const form: Form = if (std.mem.eql(u8, magic, &schema.MAGIC_SPLIT)) .split
        else if (std.mem.eql(u8, magic, &schema.MAGIC_PACKED)) .merged
        else {
            diags.add("Sax3dBadMagic", "magic is not SAX3DBIN/SAX3DPAK", .{});
            return null;
        };
    const maj = getU16(bytes, schema.Sax3dBinHeader_version_major_OFF);
    if (maj != schema.VERSION_MAJOR) {
        diags.add("Sax3dUnsupportedVersion", "version_major {d} != supported {d} (version gate)", .{ maj, schema.VERSION_MAJOR });
        return null;
    }
    const flags = getU32(bytes, schema.Sax3dBinHeader_flags_OFF);
    if (flags != 0) {
        diags.add("Sax3dBadFlags", "flags 0x{x} != 0 (v1 defines no flags; nonzero is rejected)", .{flags});
        return null;
    }
    return .{
        .form = form,
        .section_count = getU32(bytes, schema.Sax3dBinHeader_section_count_OFF),
        .nametab_off = getU32(bytes, schema.Sax3dBinHeader_nametab_off_OFF),
        .nametab_len = getU32(bytes, schema.Sax3dBinHeader_nametab_len_OFF),
    };
}

// 段表是否完整落在文件内（读任何 rec 之前必查，防截断文件越界）。
pub fn tableFits(bytes: []const u8, h: Header) bool {
    return bytes.len >= schema.Sax3dBinHeader_SIZE + @as(u64, h.section_count) * schema.Sax3dSectionRec_SIZE;
}

pub fn readRec(bytes: []const u8, i: usize) Rec {
    const base = schema.Sax3dBinHeader_SIZE + i * schema.Sax3dSectionRec_SIZE;
    return .{
        .name_off = getU32(bytes, base + schema.Sax3dSectionRec_name_off_OFF),
        .kind = getU32(bytes, base + schema.Sax3dSectionRec_kind_OFF),
        .offset = getU64(bytes, base + schema.Sax3dSectionRec_offset_OFF),
        .len = getU64(bytes, base + schema.Sax3dSectionRec_len_OFF),
        .alignment = getU32(bytes, base + schema.Sax3dSectionRec_align_OFF),
    };
}

// 名表区切片（做边界检查，越界记具名诊断）。
pub fn nameBlob(bytes: []const u8, h: Header, diags: *model.Diags) ?[]const u8 {
    const end = @as(u64, h.nametab_off) + h.nametab_len;
    if (end > bytes.len) {
        diags.add("Sax3dTruncatedFile", "name table [{d}..{d}] exceeds file size {d}", .{ h.nametab_off, end, bytes.len });
        return null;
    }
    return bytes[h.nametab_off..@intCast(end)];
}

// 按 name_off 从名表取 NUL 结尾名。
pub fn nameAt(bytes: []const u8, h: Header, name_off: u32) ?[]const u8 {
    if (name_off < h.nametab_off or name_off >= h.nametab_off + h.nametab_len) return null;
    const start: usize = @intCast(name_off);
    var end = start;
    while (end < bytes.len and bytes[end] != 0) end += 1;
    return bytes[start..end];
}
