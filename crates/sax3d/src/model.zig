// model.zig — SAX3D 组装 AST 与诊断集。
// 解析器（创作形/编译形双模）产出本 AST；裁判校验器只消费 AST，
// 不回头看文本。所有名字均为原文切片或名表解析结果（arena 生命周期）。

const std = @import("std");

pub const Diag = struct { code: []const u8, msg: []const u8 };

pub const Diags = struct {
    items: std.ArrayList(Diag) = .empty,
    alloc: std.mem.Allocator,
    pub fn init(alloc: std.mem.Allocator) Diags { return .{ .alloc = alloc }; }
    pub fn add(self: *Diags, code: []const u8, comptime fmt: []const u8, args: anytype) void {
        const msg = std.fmt.allocPrint(self.alloc, fmt, args) catch "oom";
        self.items.append(self.alloc, .{ .code = code, .msg = msg }) catch {};
    }
    pub fn count(self: *const Diags) usize { return self.items.items.len; }
    pub fn hasCode(self: *const Diags, code: []const u8) bool {
        for (self.items.items) |d| { if (std.mem.eql(u8, d.code, code)) return true; }
        return false;
    }
    pub fn printAll(self: *const Diags) void {
        for (self.items.items) |d| std.debug.print("SAX3D-E {s}: {s}\n", .{ d.code, d.msg });
    }
};

// ---------- 字面量 ----------
pub const Literal = union(enum) {
    scalar: f64,
    vec: []const f64,
    boolean: bool,
    pub fn typeName(self: Literal) []const u8 {
        return switch (self) {
            .scalar => "f32",
            .boolean => "bool",
            .vec => |v| switch (v.len) { 2 => "vec2", 3 => "vec3", 4 => "vec4", 16 => "mat4", else => "vecN" },
        };
    }
};

// ---------- 声明记录 ----------
pub const SectionDecl = struct { name: []const u8, len: u64 };
pub const BinaryDecl = struct { file: []const u8, sections: std.ArrayList(SectionDecl) = .empty };

pub const ChannelDecl = struct { name: []const u8, ty: []const u8, section: []const u8, custom: bool };
pub const MorphDecl = struct { name: []const u8, channels: std.ArrayList(ChannelDecl) = .empty };
pub const PrimDecl = struct { name: []const u8, material: []const u8 };
pub const MeshDecl = struct {
    name: []const u8,
    topology: []const u8 = "triangles",
    vertices: u64 = 0,
    has_bounds: bool = false,
    bounds_min: ?[]const f64 = null,
    bounds_max: ?[]const f64 = null,
    channels: std.ArrayList(ChannelDecl) = .empty,
    morphs: std.ArrayList(MorphDecl) = .empty,
    prims: std.ArrayList(PrimDecl) = .empty,
    idx_ty: ?[]const u8 = null,
    idx_section: []const u8 = "",
    idx_count: u64 = 0,
};

pub const JointDecl = struct {
    name: []const u8,
    parent: ?[]const u8 = null,
    has_bind: bool = false,
    bind_t: ?[]const f64 = null,
    bind_r: ?[]const f64 = null,
    bind_s: ?[]const f64 = null,
};
pub const SkeletonDecl = struct {
    name: []const u8,
    joints: std.ArrayList(JointDecl) = .empty,
    ib_section: ?[]const u8 = null,
};

pub const ImageDecl = struct {
    name: []const u8,
    source_kind: enum { section, path } = .path,
    source: []const u8 = "",
    format: []const u8 = "",
    size: ?[2]u64 = null,
    color_space: []const u8 = "",
};

pub const SamplerState = struct {
    mag: ?[]const u8 = null, min: ?[]const u8 = null, mipmap: ?[]const u8 = null,
    wrap_u: ?[]const u8 = null, wrap_v: ?[]const u8 = null, wrap_w: ?[]const u8 = null,
    present: bool = false,
};
pub const TextureDecl = struct { name: []const u8, image: []const u8 = "", sampler: SamplerState = .{} };

pub const ShaderDecl = struct { name: []const u8, slasl_path: []const u8 = "" };

pub const ParamAssign = struct { name: []const u8, lit: Literal };
pub const TexBind = struct { name: []const u8, texture: []const u8 };
pub const TexTransform = struct {
    name: []const u8,
    offset: ?[]const f64 = null,
    scale: ?[]const f64 = null,
    rotation: ?f64 = null,
};
pub const MaterialDecl = struct {
    name: []const u8,
    shader: []const u8 = "",
    params: std.ArrayList(ParamAssign) = .empty,
    texbinds: std.ArrayList(TexBind) = .empty,
    tex_transforms: std.ArrayList(TexTransform) = .empty,
    alpha: ?[]const u8 = null,
    cutoff: ?f64 = null,
    double_sided: ?bool = null,
    depth_write: ?bool = null,
};

pub const Transform = struct { t: ?[]const f64 = null, r: ?[]const f64 = null, s: ?[]const f64 = null };
pub const NodeDecl = struct {
    name: []const u8,
    transform: ?Transform = null,
    matrix: ?[]const f64 = null,
    mesh: ?[]const u8 = null,
    material: ?[]const u8 = null,
    skin: ?[]const u8 = null,
    children: std.ArrayList(NodeDecl) = .empty,
};
pub const SceneDecl = struct { name: []const u8, roots: std.ArrayList(NodeDecl) = .empty };

pub const AnimSampler = struct {
    name: []const u8,
    in_ty: []const u8 = "", in_section: []const u8 = "", in_count: u64 = 0,
    out_ty: []const u8 = "", out_section: []const u8 = "", out_count: u64 = 0,
    interpolation: []const u8 = "linear",
};
pub const ClipChannel = struct { node: []const u8 = "", path: []const u8 = "", sampler: []const u8 = "" };
pub const ClipDecl = struct {
    name: []const u8,
    samplers: std.ArrayList(AnimSampler) = .empty,
    channels: std.ArrayList(ClipChannel) = .empty,
};

pub const Asset = struct {
    name: []const u8 = "",
    version: u64 = 0,
    binary: ?BinaryDecl = null,
    shaders: std.ArrayList(ShaderDecl) = .empty,
    meshes: std.ArrayList(MeshDecl) = .empty,
    skeletons: std.ArrayList(SkeletonDecl) = .empty,
    images: std.ArrayList(ImageDecl) = .empty,
    textures: std.ArrayList(TextureDecl) = .empty,
    materials: std.ArrayList(MaterialDecl) = .empty,
    scenes: std.ArrayList(SceneDecl) = .empty,
    clips: std.ArrayList(ClipDecl) = .empty,
};

// 规范通道名集（封闭）与自定义 attr 的分界见 check.zig。
pub const CANON_CHANNELS = [_][]const u8{
    "position", "normal", "tangent",
    "uv0", "uv1", "uv2", "uv3",
    "color0", "joints0", "weights0",
};

pub fn isCanonChannel(name: []const u8) bool {
    for (CANON_CHANNELS) |c| { if (std.mem.eql(u8, c, name)) return true; }
    return false;
}

// 通道名 -> shader @input 名（格式固定映射，设计 §6.1）。
pub fn channelInputName(chan: []const u8) ?[]const u8 {
    const map = .{
        .{ "position", "position" }, .{ "normal", "normal" }, .{ "tangent", "tangent" },
        .{ "uv0", "uv" }, .{ "uv1", "uv1" }, .{ "uv2", "uv2" }, .{ "uv3", "uv3" },
        .{ "color0", "color" }, .{ "joints0", "joints" }, .{ "weights0", "weights" },
    };
    inline for (map) |e| { if (std.mem.eql(u8, chan, e[0])) return e[1]; }
    return null;
}
