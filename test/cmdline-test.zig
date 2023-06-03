const zig_lib = @import("../zig_lib.zig");
const sys = zig_lib.sys;
const mem = zig_lib.mem;
const proc = zig_lib.proc;
const spec = zig_lib.spec;
const meta = zig_lib.meta;
const build = zig_lib.build;
const builtin = zig_lib.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = true;

const Node = build.GenericNode(.{
    .options = .{ .max_cmdline_len = null },
});
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: Node.Allocator = if (Node.Allocator == mem.SimpleAllocator)
        Node.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count))
    else
        Node.Allocator.init(&address_space, Node.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const toplevel: *Node = Node.addToplevel(&allocator, args, vars);
    const g0: *Node = try toplevel.addGroup(&allocator, "g0");
    const t0: *Node = try g0.addBuild(&allocator, .{
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
    }, "target", @src().file);
    const t1: *Node = try g0.addArchive(&allocator, .{
        .operation = .r,
        .create = true,
    }, "lib0", &.{t0});

    Node.debug.toplevelCommandNotice(&allocator, toplevel);
    try builtin.expect(Node.executeToplevel(&address_space, &thread_space, &allocator, toplevel, t1, .archive));
}
