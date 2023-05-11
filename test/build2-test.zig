const top = @import("../zig_lib.zig");
const mem = top.mem;
const fmt = top.fmt;
const lit = top.lit;
const sys = top.sys;
const proc = top.proc;
const mach = top.mach;
const time = top.time;
const meta = top.meta;
const file = top.file;
const build = top.build;
const spec = top.spec;
const builtin = top.builtin;
const virtual = top.virtual;
const testing = top.testing;
const command_line = build.command_line;

pub usingnamespace proc.start;

pub const Builder = build.GenericBuilder(spec.builder.default);
pub const runtime_assertions: bool = false;

var build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .mode = .ReleaseSmall,
    .dependencies = &.{
        .{ .name = "zig_lib" },
        .{ .name = "@build" },
        .{ .name = "env" },
    },
    .image_base = 0x10000,
    .strip = true,
    .static = true,
    .compiler_rt = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .gc_sections = true,
    .omit_frame_pointer = false,
    .modules = &.{ .{
        .name = "zig_lib",
        .path = "zig_lib.zig",
    }, .{
        .name = "@build",
        .path = "build.zig",
    }, .{
        .name = "env",
        .path = "zig-cache/env.zig",
    } },
};
fn addEnvPathArgs(allocator: *Builder.Allocator, builder: *Builder, target: *Builder.Target) void {
    target.addRunArgument(allocator, builder.zig_exe);
    target.addRunArgument(allocator, builder.build_root);
    target.addRunArgument(allocator, builder.cache_root);
    target.addRunArgument(allocator, builder.global_cache_root);
}
fn testBuildRunner(args: [][*:0]u8, vars: [][*:0]u8, comptime main_fn: anytype) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: Builder.Allocator = Builder.Allocator.init(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const cmds: [][*:0]u8 = args[5..];
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try main_fn(&allocator, &builder);
    var target_task: build.Task = .build;
    for (cmds, 0..) |arg, idx| {
        const command: []const u8 = meta.manyToSlice(arg);
        if (builder.args_len == builder.args.len) {
            if (mach.testEqualMany8(command, "build")) {
                target_task = .build;
                continue;
            } else if (mach.testEqualMany8(command, "--")) {
                builder.args_len = idx +% 6;
                continue;
            } else if (mach.testEqualMany8(command, "run")) {
                target_task = .run;
                continue;
            } else if (mach.testEqualMany8(command, "show")) {
                return Builder.debug.builderCommandNotice(&builder, true, true, true);
            }
        }
        for (builder.groups()) |group| {
            if (mach.testEqualMany8(command, group.name)) {
                try meta.wrap(group.executeToplevel(&address_space, &thread_space, &allocator, target_task));
            } else for (group.targets()) |target| {
                if (mach.testEqualMany8(command, target.name)) {
                    try meta.wrap(target.executeToplevel(&address_space, &thread_space, &allocator, &builder, target_task));
                }
            }
        }
    }
}
fn testCompileError() void {
    @compileError(
        \\0
        \\1
        \\2
    );
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try testBuildRunner(args, vars, @import("../build.zig").buildMain);
}
