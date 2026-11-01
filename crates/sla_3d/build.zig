const std = @import("std");

// sla_3d native support libraries (Jev ruling F2): the batch-A modules'
// Zig kernels, migrated from the sa_plugin_3dengines plugin hosts with
// the plugin-framework glue lines replaced by registration against
// the crate-local ABI shim native/saasm_abi.zig (see native/
// provenance in crate.toml). The domains' SA layout tests load these libraries via
// SA_PLUGINS_PATH, exactly as in the source family; `zig build test`
// also runs the unit tests embedded in the kernel sources.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const test_step = b.step("test", "Run sla_3d native support-library unit tests");
    inline for (.{ "math", "time", "transform" }) |domain| {
        const mod = b.createModule(.{
            .root_source_file = b.path("native/" ++ domain ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        const lib = b.addLibrary(.{ .name = "3d_" ++ domain, .root_module = mod, .linkage = .dynamic });
        b.installArtifact(lib);
        const tests = b.addTest(.{ .root_module = mod });
        test_step.dependOn(&b.addRunArtifact(tests).step);
    }
}
