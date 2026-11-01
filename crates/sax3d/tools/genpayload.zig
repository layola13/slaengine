// genpayload.zig — 测试载荷生成器（验收专用，不随工具链交付）。
// 用法: genpayload <outdir> <name:size> [<name:size> ...]
// 产出 <outdir>/<name>.bin，全零字节（零是合法 f32、时间轴平凡单调、
// 像素全零——格式层验收只对长度/布局负责，内容语义不在此层）。

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(alloc);
    if (argv.len < 3) { std.debug.print("usage: genpayload <outdir> <name:size>...\n", .{}); return error.Usage; }
    const dir = argv[1];
    std.Io.Dir.cwd().createDirPath(init.io, dir) catch {};
    for (argv[2..]) |spec| {
        const colon = std.mem.indexOfScalar(u8, spec, ':') orelse return error.BadSpec;
        const name = spec[0..colon];
        const size = try std.fmt.parseInt(usize, spec[colon + 1 ..], 10);
        const data = try alloc.alloc(u8, size);
        @memset(data, 0);
        const path = try std.fmt.allocPrint(alloc, "{s}/{s}.bin", .{ dir, name });
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = path, .data = data });
        std.debug.print("genpayload: {s} ({d}B)\n", .{ path, size });
    }
}
