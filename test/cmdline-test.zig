const zig_lib = @import("../zig_lib.zig");
const sys = zig_lib.sys;
const mem = zig_lib.mem;
const proc = zig_lib.proc;
const spec = zig_lib.spec;
const meta = zig_lib.meta;
const build = zig_lib.build;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = true;

const Node = build.GenericNode(.{
    .options = .{ .max_cmdline_len = null },
});
pub fn testComplexStructureBuildMain(allocator: *Node.Allocator, builder: *Node) void {
    const deps: []const build.ModuleDependency = &.{
        .{ .name = "context" }, .{ .name = "zig_lib" }, .{ .name = "@build" },
    };
    const mods: []const build.Module = &.{
        .{ .name = "context", .path = "zig-cache/context.zig" },
        .{ .name = "zig_lib", .path = "zig_lib.zig" },
        .{ .name = "@build", .path = "./build.zig" },
    };
    var build_cmd: build.BuildCommand = .{
        .kind = .exe,
        .mode = .ReleaseSmall,
        .dependencies = deps[0..1],
        .modules = mods[0..1],
        .image_base = 0x10000,
        .strip = true,
        .compiler_rt = false,
        .reference_trace = true,
        .single_threaded = true,
        .function_sections = true,
        .gc_sections = true,
        .omit_frame_pointer = false,
    };
    var archive_cmd = build.ArchiveCommand{
        .operation = .r,
        .create = true,
    };
    var format_cmd = build.FormatCommand{
        .ast_check = true,
    };
    const objsa: *Node = try builder.addGroup(allocator, "objsA");
    const objsb: *Node = try objsa.addGroup(allocator, "objsB");
    const libs: *Node = try builder.addGroup(allocator, "libs");
    const bin: *Node = try builder.addBuild(allocator, build_cmd, "bin", "examples/hello.zig");
    build_cmd.kind = .obj;
    const obj0: *Node = try builder.addBuild(allocator, build_cmd, "obj01234", "test/src/obj0.zig");
    const obj1: *Node = try objsa.addBuild(allocator, build_cmd, "obj12", "test/src/obj1.zig");
    const obj2: *Node = try objsa.addBuild(allocator, build_cmd, "obj234", "test/src/obj2.zig");
    const obj3: *Node = try objsb.addBuild(allocator, build_cmd, "obj3456", "test/src/obj3.zig");
    const obj4: *Node = try objsb.addBuild(allocator, build_cmd, "obj45678", "test/src/obj4.zig");
    const obj5: *Node = try objsb.addBuild(allocator, build_cmd, "obj5678910", "test/src/obj5.zig");
    build_cmd.kind = .lib;
    const dylib: *Node = try libs.addBuild(allocator, build_cmd, "dylib0", "test/src/lib0.zig");
    const lib: *Node = try builder.addArchive(allocator, archive_cmd, "lib1", &.{ obj2, obj3, obj4 });
    const fmt: *Node = try builder.addFormat(allocator, format_cmd, "fmt0", "test/src");
    for ([_]*Node{ obj0, obj1, obj2, obj3, obj4, obj5 }) |obj| {
        obj.hidden = true;
    }
    libs.dependOn(allocator, dylib, null);
    libs.dependOn(allocator, lib, null);
    dylib.dependOnObject(allocator, obj1);
    dylib.dependOnObject(allocator, obj2);
    dylib.dependOnObject(allocator, obj3);
    bin.dependOn(allocator, fmt, .format);
    bin.dependOnObject(allocator, obj0);
    bin.dependOnObject(allocator, obj5);
    bin.dependOnObject(allocator, dylib);
    obj0.addDescr("Zeroth object file");
    obj1.addDescr("First object file");
    obj2.addDescr("Second object file");
    obj3.addDescr("Third object file");
    obj4.addDescr("Fourth object file");
    obj5.addDescr("Fifth object file");
    lib.addDescr("Zeroth archive");
    dylib.addDescr("Zeroth shared object file");
    bin.addDescr("Binary executable");
    fmt.addDescr("Reformat source directory into canonical form");
}
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
    const toplevel: *Node = Node.init(&allocator, args, vars);
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
    try builtin.expect(Node.executeToplevel(&address_space, &thread_space, &allocator, toplevel, t1, .archive));
}
