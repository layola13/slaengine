// SA plugin ABI shim for the sla_3d native support libraries.
//
// Why this file exists: the SA host loads a bare .so in dev mode
// (SA_PLUGINS_PATH=<lib.so>) only when the library exports the plugin
// descriptor symbols `saasm_plugin_descriptor_v1` /
// `saasm_plugin_descriptor_v1_fn`, and validates abi_version and
// descriptor_size against its own ABI (sci src/plugins.zig:
// loadDescriptor / validateDescriptor). The domains' SA layout tests
// resolve their extern selftest entry points through that loading, so
// a support library without the descriptor is not loadable and the
// tests cannot link.
//
// In the source family the descriptor came from the plugin framework
// (common/module_plugin.zig), whose CLI command handler and skill
// registry are plugin-host scaffolding retired by the takeover
// (survey plan section 4.3: common/ not imported, host shells retire).
// This shim keeps exactly the ABI surface the host requires — the
// descriptor identity — and nothing else: handle_command is null and
// the skill list is empty. Per the engine language doctrine the
// native kernels are an auxiliary surface behind the ABI; this file
// is that surface's registration point.
//
// The ABI types below are the SA plugin ABI (abi_version 1), carried
// verbatim from the source family's common/plugin_api.zig (which
// itself mirrors sci's plugin ABI definitions).

const std = @import("std");

pub const SkillSection = struct {
    name: []const u8,
    summary: []const u8,
    items: []const []const u8,
};

pub const Context = struct {
    allocator: std.mem.Allocator,
    host_version: ?[]const u8 = null,
    log: ?*const fn (ctx: *const anyopaque, level: LogLevel, message_ptr: [*]const u8, message_len: usize) callconv(.c) void = null,
    log_ctx: ?*anyopaque = null,
    json_mode: bool = false,
};

pub const LogLevel = enum(u8) {
    debug,
    info,
    warn,
    err,
};

pub const abi_version: u32 = 1;
pub const host_version: []const u8 = "sci-0.1";

pub const AbiStatus = enum(u32) {
    ok = 0,
    unknown_command = 1,
    failed = 2,
    version_mismatch = 3,
    invalid_descriptor = 4,
};

pub const StreamWriteAllFn = *const fn (ctx: ?*anyopaque, bytes: [*]const u8, len: usize) callconv(.c) u32;

pub const HostStream = extern struct {
    ctx: ?*anyopaque,
    write_all: ?StreamWriteAllFn,
};

pub const PluginDescriptor = extern struct {
    abi_version: u32,
    descriptor_size: u32,
    name: [*:0]const u8,
    init: ?*const fn (ctx: *const Context) callconv(.c) u32,
    prebuild: ?*const fn (ctx: *const Context, compile_options: ?*anyopaque) callconv(.c) u32,
    postbuild: ?*const fn (ctx: *const Context) callconv(.c) u32,
    handle_command: ?*const fn (ctx: *const Context, argv: [*]const [*:0]const u8, argv_len: usize, stdout: HostStream, stderr: HostStream, out_code: *u8) callconv(.c) u32,
    skills_ptr: [*]const SkillSection,
    skills_len: usize,
};

const empty_skills = [_]SkillSection{};

/// The descriptor registration for one support library, in the same
/// shape the source family's framework produced (identity fields
/// only). Instantiate with the domain's plugin name and re-export the
/// two symbols from the library root.
pub fn Plugin(comptime name: [*:0]const u8) type {
    return struct {
        pub const descriptor = PluginDescriptor{
            .abi_version = abi_version,
            .descriptor_size = @as(u32, @intCast(@sizeOf(PluginDescriptor))),
            .name = name,
            .init = null,
            .prebuild = null,
            .postbuild = null,
            .handle_command = null,
            .skills_ptr = empty_skills[0..].ptr,
            .skills_len = 0,
        };

        pub export const saasm_plugin_descriptor_v1: PluginDescriptor = descriptor;

        pub export fn saasm_plugin_descriptor_v1_fn(out: *PluginDescriptor) callconv(.c) void {
            out.* = descriptor;
        }
    };
}
