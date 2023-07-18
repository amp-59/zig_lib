const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const proc = zl.proc;
const spec = zl.spec;
const meta = zl.meta;
const build = zl.build;
const builtin = zl.builtin;
const testing = zl.testing;

pub usingnamespace zl.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

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
    builtin.debug.write(array.readAll());
}
fn testManyCompileOptionsWithArguments(args: anytype, vars: anytype) !void {
    const build_cmd = .{
        .kind = .obj,
        .allow_shlib_undefined = true,
        .build_id = .sha1,
        .cflags = &.{ "-O3", "-Wno-parentheses", "-Wno-format-security" },
        .macros = &.{
            .{ .name = "true", .value = "false" },
            .{ .name = "false", .value = "true" },
            .{ .name = "__zig__" },
        },
        .clang = true,
        .code_model = .default,
        .color = .auto,
        .compiler_rt = false,
        .compress_debug_sections = true,
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
        .z = &.{ .nodelete, .notext },
        .mode = .Debug,
        .strip = true,
    };
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    Node.initState(args, vars);
    const toplevel: *Node = Node.init(&allocator);

    const g0: *Node = toplevel.addGroup(&allocator, "g0");
    const t0: *Node = g0.addBuild(&allocator, build_cmd, "target", @src().file);
    const t1: *Node = g0.addArchive(&allocator, .{
        .operation = .r,
        .create = true,
    }, "lib0", &.{t0});

    testing.print(fmt.any(t1));
    try builtin.expect(Node.executeToplevel(&address_space, &thread_space, &allocator, toplevel, t1, .archive));
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try testManyCompileOptionsWithArguments(args, vars);
    testConfigValues();
}
