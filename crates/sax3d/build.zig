const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const sax3dc = b.addExecutable(.{ .name = "sax3dc", .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    b.installArtifact(sax3dc);

    const readback = b.addExecutable(.{ .name = "readback", .root_module = b.createModule(.{
        .root_source_file = b.path("tools/readback.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "sax3d", .module = lib }},
    }) });
    b.installArtifact(readback);

    const genpayload = b.addExecutable(.{ .name = "genpayload", .root_module = b.createModule(.{
        .root_source_file = b.path("tools/genpayload.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    b.installArtifact(genpayload);

    const convert = b.addExecutable(.{ .name = "convert", .root_module = b.createModule(.{
        .root_source_file = b.path("tools/convert.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "sax3d", .module = lib }},
    }) });
    b.installArtifact(convert);

    const genref = b.addExecutable(.{ .name = "genref", .root_module = b.createModule(.{
        .root_source_file = b.path("tools/genref.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    b.installArtifact(genref);

    const gen_schema = b.addExecutable(.{ .name = "gen_schema", .root_module = b.createModule(.{
        .root_source_file = b.path("tools/gen_schema.zig"),
        .target = target,
        .optimize = optimize,
    }) });
    b.installArtifact(gen_schema);
}
