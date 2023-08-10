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

const Node = build.GenericNode(.{ .options = .{
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
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));

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
        .cpu = "x86_64",
        .dynamic = true,
        .dirafter = "after",
        .dynamic_linker = "/usr/bin/ld",
        .library_directory = &.{ "/usr/lib64", "/usr/lib32" },
        .include = &.{ "/usr/include", "/usr/include/c++" },
        .each_lib_rpath = true,
        .entry = "_start",
        .error_tracing = true,
        .format = .elf,
        .verbose_air = true,
        .verbose_cc = true,
        .verbose_cimport = true,
        .lflags = &.{.nodelete},
        .mode = .Debug,
        .strip = true,
        .dependencies = &.{
            .{ .name = "zig_lib" },
            .{ .name = "@build" },
        },
        .modules = &.{
            .{ .name = "zig_lib", .path = Node.lib_build_root ++ "/zig_lib.zig" },
            .{ .name = "@build", .path = "./build.zig" },
        },
    };
    if (args.len < 5) {
        proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    const toplevel: *Node = Node.init(&allocator, args, vars);
    const g0: *Node = toplevel.addGroup(&allocator, "g0");
    const t0: *Node = g0.addBuild(&allocator, build_cmd, "target", @src().file);
    const t1: *Node = g0.addArchive(&allocator, .{ .operation = .r, .create = true }, "lib0", &.{t0});
    _ = t1;
    Node.updateCommands(&allocator, toplevel);
    Node.processCommands(&address_space, &thread_space, &allocator, toplevel);
}
pub usingnamespace if (@import("builtin").output_mode == .Obj) struct {
    pub export fn _start() void {}
    pub fn main() void {}
} else struct {
    pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
        try testManyCompileOptionsWithArguments(args, vars);
        testConfigValues();
    }
};
