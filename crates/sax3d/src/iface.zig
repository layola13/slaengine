// iface.zig — SLASL 接口表夹具（GAP-1 的 v1 处置）。
// 生产形接口表是 SLASL 编译器核心的产物（可哈希清单）；其 artefact 格式
// 未定形前，v1 以本手工夹具格式代演（与研究线原型同形 + 默认值标记）：
//
//   == params ==
//     base_color: vec4
//     metallic: f32 = 0.0        // 带 = 默认值者可被材质省略（设计 §6.3）
//   == textures ==
//     base_color_map: sampler2D
//   == inputs ==
//     position: vec3
//
// 以 `block ...` 开头的行是 SLASL 金文件式布局头，跳过。

const std = @import("std");
const model = @import("model.zig");

pub const Iface = struct {
    params: std.StringHashMap(Param) = undefined,
    textures: std.StringHashMap([]const u8) = undefined,
    inputs: std.StringHashMap([]const u8) = undefined,
    pub const Param = struct { ty: []const u8, has_default: bool, default_scalar: ?f64 = null };
};

pub fn parseIface(alloc: std.mem.Allocator, src: []const u8, diags: *model.Diags, shader_name: []const u8) Iface {
    var f = Iface{
        .params = .init(alloc),
        .textures = .init(alloc),
        .inputs = .init(alloc),
    };
    var mode: u8 = 0;
    var lines = std.mem.splitScalar(u8, src, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line, "== params ==")) { mode = 1; continue; }
        if (std.mem.eql(u8, line, "== textures ==")) { mode = 2; continue; }
        if (std.mem.eql(u8, line, "== inputs ==")) { mode = 3; continue; }
        if (std.mem.startsWith(u8, line, "block")) continue;
        if (mode == 0) { diags.add("Sax3dFixtureError", "iface for shader '{s}': entry outside any section: '{s}'", .{ shader_name, line }); continue; }
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse {
            diags.add("Sax3dFixtureError", "iface for shader '{s}': malformed entry '{s}'", .{ shader_name, line });
            continue;
        };
        const nm = std.mem.trim(u8, line[0..colon], " ");
        var rest = std.mem.trim(u8, line[colon + 1 ..], " ");
        var has_default = false;
        var default_scalar: ?f64 = null;
        if (std.mem.indexOfScalar(u8, rest, '=')) |eq| {
            has_default = true;
            const dflt = std.mem.trim(u8, rest[eq + 1 ..], " ");
            default_scalar = std.fmt.parseFloat(f64, dflt) catch null;
            rest = std.mem.trim(u8, rest[0..eq], " ");
        }
        switch (mode) {
            1 => f.params.put(nm, .{ .ty = rest, .has_default = has_default, .default_scalar = default_scalar }) catch {},
            2 => f.textures.put(nm, rest) catch {},
            else => f.inputs.put(nm, rest) catch {},
        }
    }
    return f;
}
