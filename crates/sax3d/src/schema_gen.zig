// GENERATED from sax3d.sai by tools/gen_schema.zig — DO NOT EDIT.
// Layout truth lives in sax3d.sai only; regenerate, never hand-sync.

pub const VERSION_MAJOR: u16 = 1;
pub const VERSION_MINOR: u16 = 0;
pub const MAGIC_SPLIT = "SAX3DBIN".*;
pub const MAGIC_PACKED = "SAX3DPAK".*;
pub const Sax3dBinHeader_SIZE: usize = 32;
pub const Sax3dBinHeader_magic_OFF: usize = 0;
pub const Sax3dBinHeader_version_major_OFF: usize = 8;
pub const Sax3dBinHeader_version_minor_OFF: usize = 10;
pub const Sax3dBinHeader_section_count_OFF: usize = 12;
pub const Sax3dBinHeader_flags_OFF: usize = 16;
pub const Sax3dBinHeader_nametab_off_OFF: usize = 20;
pub const Sax3dBinHeader_nametab_len_OFF: usize = 24;
pub const Sax3dBinHeader_reserved_OFF: usize = 28;
pub const Sax3dSectionRec_SIZE: usize = 32;
pub const Sax3dSectionRec_name_off_OFF: usize = 0;
pub const Sax3dSectionRec_kind_OFF: usize = 4;
pub const Sax3dSectionRec_offset_OFF: usize = 8;
pub const Sax3dSectionRec_len_OFF: usize = 16;
pub const Sax3dSectionRec_align_OFF: usize = 24;
pub const Sax3dSectionRec_reserved_OFF: usize = 28;
pub const SectionKind = enum(u32) {
    channel = 1,
    index = 2,
    image_raw = 3,
    anim_input = 4,
    anim_output = 5,
    inverse_bind = 6,
    blob = 7,
    assembly = 8,
    pub fn fromU32(v: u32) ?SectionKind { return std.enums.fromInt(SectionKind, v); }
};
const std = @import("std");

pub const ElemType = struct { name: []const u8, size: u64, alignment: u32 };
pub const ELEM_TYPES = [_]ElemType{
    .{ .name = "f32", .size = 4, .alignment = 4 },
    .{ .name = "f32x2", .size = 8, .alignment = 8 },
    .{ .name = "f32x3", .size = 12, .alignment = 4 },
    .{ .name = "f32x4", .size = 16, .alignment = 16 },
    .{ .name = "quat", .size = 16, .alignment = 16 },
    .{ .name = "u8x4", .size = 4, .alignment = 4 },
    .{ .name = "u16x4", .size = 8, .alignment = 8 },
    .{ .name = "u32", .size = 4, .alignment = 4 },
    .{ .name = "u16", .size = 2, .alignment = 2 },
    .{ .name = "f32x4x4", .size = 64, .alignment = 16 },
};
pub fn elemType(name: []const u8) ?ElemType { for (ELEM_TYPES) |e| { if (std.mem.eql(u8, e.name, name)) return e; } return null; }
