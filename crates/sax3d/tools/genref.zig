// genref.zig — 体积对拍参照件生成器（验收专用）。
// 用与 SAX3D 例完全相同的载荷字节，为立方体例产等价内容的
// glTF (.gltf+.bin) 与 GLB 两份参照件，并打印各项字节数。
// 等价口径：几何/动画载荷逐字节同源（同一批 payload 文件）；
// 图像在 glTF 侧只能以 PNG 承载（glTF 无 raw 图像形）——生成一份
// 真实最小 PNG（2x2 全零 RGBA，与 raw 载荷的像素内容一致），
// 编码差如实计入并注记，不删改任一方内容。
// 用法: genref <payload-dir> <out-dir>

const std = @import("std");

fn crc32(data: []const u8) u32 {
    var crc: u32 = 0xFFFF_FFFF;
    for (data) |byte| {
        crc ^= byte;
        for (0..8) |_| crc = (crc >> 1) ^ (0xEDB8_8320 & (0 -% (crc & 1)));
    }
    return crc ^ 0xFFFF_FFFF;
}

fn adler32(data: []const u8) u32 {
    var a: u32 = 1;
    var b: u32 = 0;
    for (data) |byte| { a = (a + byte) % 65521; b = (b + a) % 65521; }
    return (b << 16) | a;
}

fn chunk(alloc: std.mem.Allocator, out: *std.ArrayList(u8), typ: []const u8, data: []const u8) !void {
    var lenb: [4]u8 = undefined;
    std.mem.writeInt(u32, &lenb, @intCast(data.len), .big);
    try out.appendSlice(alloc, &lenb);
    try out.appendSlice(alloc, typ);
    try out.appendSlice(alloc, data);
    var crc_data: std.ArrayList(u8) = .empty;
    try crc_data.appendSlice(alloc, typ);
    try crc_data.appendSlice(alloc, data);
    var crcb: [4]u8 = undefined;
    std.mem.writeInt(u32, &crcb, crc32(crc_data.items), .big);
    try out.appendSlice(alloc, &crcb);
}

// 最小 PNG：2x2 RGBA8，全零像素（与 raw-rgba8 载荷同像素内容）。
fn buildPng(alloc: std.mem.Allocator) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    try out.appendSlice(alloc, &.{ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A });
    var ihdr: [13]u8 = @splat(0);
    std.mem.writeInt(u32, ihdr[0..4], 2, .big);
    std.mem.writeInt(u32, ihdr[4..8], 2, .big);
    ihdr[8] = 8; // bit depth
    ihdr[9] = 6; // color type RGBA
    try chunk(alloc, &out, "IHDR", &ihdr);
    // 原始扫描线：2 行 x (滤波字节 0 + 8B 像素) = 18B 全零
    const raw: [18]u8 = @splat(0);
    var idat: std.ArrayList(u8) = .empty;
    try idat.appendSlice(alloc, &.{ 0x78, 0x01 }); // zlib 头
    try idat.append(alloc, 0x01); // stored block, final
    var lb: [2]u8 = undefined;
    std.mem.writeInt(u16, &lb, raw.len, .little);
    try idat.appendSlice(alloc, &lb);
    std.mem.writeInt(u16, &lb, ~@as(u16, raw.len), .little);
    try idat.appendSlice(alloc, &lb);
    try idat.appendSlice(alloc, &raw);
    var ab: [4]u8 = undefined;
    std.mem.writeInt(u32, &ab, adler32(&raw), .big);
    try idat.appendSlice(alloc, &ab);
    try chunk(alloc, &out, "IDAT", idat.items);
    try chunk(alloc, &out, "IEND", &.{});
    return out.items;
}

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(alloc);
    if (argv.len < 3) { std.debug.print("usage: genref <payload-dir> <out-dir>\n", .{}); return error.Usage; }
    const pdir = argv[1];
    const odir = argv[2];
    std.Io.Dir.cwd().createDirPath(init.io, odir) catch {};

    const names = [_][]const u8{ "positions", "normals", "uvs", "indices", "spin_times", "spin_rots" };
    var parts: std.ArrayList([]const u8) = .empty;
    for (names) |n| {
        const p = try std.fmt.allocPrint(alloc, "{s}/{s}.bin", .{ pdir, n });
        try parts.append(alloc, try std.Io.Dir.cwd().readFileAlloc(init.io, p, alloc, .limited(1 << 24)));
    }
    const png = try buildPng(alloc);

    // .bin 布局（bufferView 序）：pos, nrm, uv, idx, image(PNG), times, rots
    var bin: std.ArrayList(u8) = .empty;
    var offs: std.ArrayList(u64) = .empty;
    const order = [_]usize{ 0, 1, 2, 3, 999, 4, 5 };
    for (order) |oi| {
        try offs.append(alloc, bin.items.len);
        if (oi == 999) try bin.appendSlice(alloc, png) else try bin.appendSlice(alloc, parts.items[oi]);
    }
    const bin_len = bin.items.len;

    var json: std.Io.Writer.Allocating = .init(alloc);
    const jw = &json.writer;
    try jw.print("{{\"asset\":{{\"version\":\"2.0\",\"generator\":\"sax3d-genref\"}},\"scene\":0,\"scenes\":[{{\"nodes\":[0]}}],\"nodes\":[{{\"name\":\"CubeNode\",\"mesh\":0}}],\"meshes\":[{{\"name\":\"Cube\",\"primitives\":[{{\"attributes\":{{\"POSITION\":0,\"NORMAL\":1,\"TEXCOORD_0\":2}},\"indices\":3,\"material\":0}}]}}],\"materials\":[{{\"name\":\"RedPlastic\",\"pbrMetallicRoughness\":{{\"baseColorFactor\":[0.8,0.1,0.1,1.0],\"baseColorTexture\":{{\"index\":0}},\"roughnessFactor\":0.6,\"metallicFactor\":0.0}}}}],\"textures\":[{{\"source\":0,\"sampler\":0}}],\"samplers\":[{{\"magFilter\":9729,\"minFilter\":9729,\"wrapS\":10497,\"wrapT\":10497}}],\"images\":[{{\"name\":\"CheckerImg\",\"bufferView\":4,\"mimeType\":\"image/png\"}}],\"animations\":[{{\"name\":\"Spin\",\"channels\":[{{\"sampler\":0,\"target\":{{\"node\":0,\"path\":\"rotation\"}}}}],\"samplers\":[{{\"input\":5,\"interpolation\":\"LINEAR\",\"output\":6}}]}}],\"bufferViews\":[", .{});
    const bv = .{
        .{ 0, 288, ",\"target\":34962" }, .{ 1, 288, ",\"target\":34962" }, .{ 2, 192, ",\"target\":34962" },
        .{ 3, 72, ",\"target\":34963" }, .{ 4, 0, "" }, .{ 5, 8, "" }, .{ 6, 32, "" },
    };
    inline for (bv, 0..) |b, i| {
        if (i > 0) try jw.print(",", .{});
        const len: u64 = if (b[0] == 4) png.len else parts.items[if (b[0] == 5) 4 else if (b[0] == 6) 5 else b[0]].len;
        try jw.print("{{\"buffer\":0,\"byteOffset\":{d},\"byteLength\":{d}{s}}}", .{ offs.items[i], len, b[2] });
    }
    try jw.print("],\"accessors\":[{{\"bufferView\":0,\"componentType\":5126,\"count\":24,\"type\":\"VEC3\"}},{{\"bufferView\":1,\"componentType\":5126,\"count\":24,\"type\":\"VEC3\"}},{{\"bufferView\":2,\"componentType\":5126,\"count\":24,\"type\":\"VEC2\"}},{{\"bufferView\":3,\"componentType\":5123,\"count\":36,\"type\":\"SCALAR\"}},{{\"bufferView\":5,\"componentType\":5126,\"count\":2,\"type\":\"SCALAR\"}},{{\"bufferView\":6,\"componentType\":5126,\"count\":2,\"type\":\"VEC4\"}}],\"buffers\":[{{\"byteLength\":{d}}}]}}", .{bin_len});
    const json_bytes = json.written();

    const gltf_path = try std.fmt.allocPrint(alloc, "{s}/cube.gltf", .{odir});
    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = gltf_path, .data = json_bytes });
    const bin_path = try std.fmt.allocPrint(alloc, "{s}/cube.bin", .{odir});
    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = bin_path, .data = bin.items });

    // GLB：头 12B + JSON 块（空格填充至 4）+ BIN 块（零填充至 4）
    var glb: std.ArrayList(u8) = .empty;
    const json_pad = (4 - (json_bytes.len % 4)) % 4;
    const bin_pad = (4 - (bin_len % 4)) % 4;
    const total = 12 + 8 + json_bytes.len + json_pad + 8 + bin_len + bin_pad;
    var hb: [4]u8 = undefined;
    std.mem.writeInt(u32, &hb, 0x46546C67, .little);
    try glb.appendSlice(alloc, &hb);
    std.mem.writeInt(u32, &hb, 2, .little);
    try glb.appendSlice(alloc, &hb);
    std.mem.writeInt(u32, &hb, @intCast(total), .little);
    try glb.appendSlice(alloc, &hb);
    std.mem.writeInt(u32, &hb, @intCast(json_bytes.len + json_pad), .little);
    try glb.appendSlice(alloc, &hb);
    std.mem.writeInt(u32, &hb, 0x4E4F534A, .little);
    try glb.appendSlice(alloc, &hb);
    try glb.appendSlice(alloc, json_bytes);
    for (0..json_pad) |_| try glb.append(alloc, ' ');
    std.mem.writeInt(u32, &hb, @intCast(bin_len + bin_pad), .little);
    try glb.appendSlice(alloc, &hb);
    std.mem.writeInt(u32, &hb, 0x004E4942, .little);
    try glb.appendSlice(alloc, &hb);
    try glb.appendSlice(alloc, bin.items);
    for (0..bin_pad) |_| try glb.append(alloc, 0);
    const glb_path = try std.fmt.allocPrint(alloc, "{s}/cube.glb", .{odir});
    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = glb_path, .data = glb.items });

    std.debug.print("REF json_len={d} bin_len={d} png_len={d} glb_total={d} json_chunk_padded={d}\n", .{ json_bytes.len, bin_len, png.len, total, json_bytes.len + json_pad });
}
