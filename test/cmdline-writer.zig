const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const proc = zl.proc;
const spec = zl.spec;
const meta = zl.meta;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

pub const Builder = build.GenericBuilder(.{ .options = .{
    .max_cmdline_len = null,
} });

fn testConfigValues() void {
    const colour = build.Config{ .name = "color", .value = .{ .Bool = true } };
    const size = build.Config{ .name = "size", .value = .{ .Int = 128 } };
    const name = build.Config{ .name = "name", .value = .{ .String = "zero" } };
    var array: mem.StaticString(4096) = .{};
    array.impl.ub_word +%= colour.formatWriteBuf(array.referAllUndefined().ptr);
    array.impl.ub_word +%= size.formatWriteBuf(array.referAllUndefined().ptr);
    array.impl.ub_word +%= name.formatWriteBuf(array.referAllUndefined().ptr);
    debug.write(array.readAll());
}
fn makeArgPtrs(allocator: *mem.SimpleAllocator, args: [:0]u8) [][*:0]u8 {
    @setRuntimeSafety(false);
    var count: u64 = 0;
    for (args) |value| {
        count +%= @intFromBool(value == 0);
    }
    const ptrs: [*][*:0]u8 = @as([*][*:0]u8, @ptrFromInt(allocator.allocateRaw(8 *% (count +% 1), 1)));
    var len: usize = 0;
    var idx: usize = 0;
    var pos: u64 = 0;
    while (idx != args.len) : (idx +%= 1) {
        if (args[idx] == 0) {
            ptrs[len] = args[pos..idx :0];
            len +%= 1;
            pos = idx +% 1;
        }
    }
    ptrs[len] = comptime builtin.zero([*:0]u8);
    return ptrs[0..len];
}
pub const exec_mode: build.ExecMode = .Run;
fn testManyCompileOptionsWithArguments(args: anytype, vars: anytype) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.init_arena(
        Builder.AddressSpace.arena(Builder.specification.options.max_thread_count),
    );

    var path: build.Path = .{ .names = @constCast(&[_][:0]const u8{"any"}) };
    var build_cmd: build.BuildCommand = .{
        .kind = .obj,
        .allow_shlib_undefined = true,
        .build_id = .sha1,
        .cflags = &.{ "-O3", "-Wno-parentheses", "-Wno-format-security" },
        .emit_bin = .{ .yes = path },
        .macros = &.{
            .{ .name = "true", .value = "false" },
            .{ .name = "false", .value = "true" },
            .{ .name = "__zig__" },
        },
        .code_model = .default,
        .color = .auto,
        .compiler_rt = false,
        //.cpu = "x86_64",
        //.dynamic = true,
        //.dirafter = "after",
        .dynamic_linker = "/usr/bin/ld",
        .library_directory = &.{ "/usr/lib64", "/usr/lib32" },
        .include = &.{ "/usr/include", "/usr/include/c++" },
        .each_lib_rpath = true,
        .error_tracing = true,
        .format = .elf,
        .verbose_air = true,
        .verbose_cc = true,
        .verbose_cimport = true,
        .lflags = &.{.nodelete},
        .mode = .Debug,
        .strip = true,
        //.dependencies = &.{
        //    .{ .name = "zig_lib" },
        //    .{ .name = "@build" },
        //},
        //.modules = &.{
        //    .{ .name = "zig_lib", .path = builtin.lib_root ++ "/zig_lib.zig" },
        //    .{ .name = "@build", .path = "./build.zig" },
        //},
    };
    if (args.len < 5) {
        proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    const toplevel: *build.Node = build.Node.create(&allocator, "toplevel", args, vars);
    const g0: *build.Node = toplevel.addGroup(&allocator, "g0", .{});
    const t0: *build.Node = g0.addBuild(&allocator, build_cmd, "target", @src().file);
    _ = t0;
    //const t1: *build.Node = g0.addArchive(&allocator, .{ .operation = .r, .create = true }, "lib0", &.{t0});
    Builder.updateCommands(&allocator, toplevel);
    Builder.processCommands(&address_space, &thread_space, &allocator, toplevel);
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try testManyCompileOptionsWithArguments(args, vars);
    testConfigValues();
}
