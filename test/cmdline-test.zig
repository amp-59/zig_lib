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

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

const Node = build.GenericNode(.{ .options = .{
    .commands = .{ .archive = true },
    .max_cmdline_len = null,
} });

pub fn testComplexStructureBuildMain(allocator: *build.Allocator, builder: *Node) void {
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
    const objsa: *Node = builder.addGroup(allocator, "objsA");
    const objsb: *Node = objsa.addGroup(allocator, "objsB");
    const libs: *Node = builder.addGroup(allocator, "libs");
    const bin: *Node = builder.addBuild(allocator, build_cmd, "bin", "examples/hello.zig");
    build_cmd.kind = .obj;
    const obj0: *Node = builder.addBuild(allocator, build_cmd, "obj01234", "test/src/obj0.zig");
    const obj1: *Node = objsa.addBuild(allocator, build_cmd, "obj12", "test/src/obj1.zig");
    const obj2: *Node = objsa.addBuild(allocator, build_cmd, "obj234", "test/src/obj2.zig");
    const obj3: *Node = objsb.addBuild(allocator, build_cmd, "obj3456", "test/src/obj3.zig");
    const obj4: *Node = objsb.addBuild(allocator, build_cmd, "obj45678", "test/src/obj4.zig");
    const obj5: *Node = objsb.addBuild(allocator, build_cmd, "obj5678910", "test/src/obj5.zig");
    build_cmd.kind = .lib;
    const dylib: *Node = libs.addBuild(allocator, build_cmd, "dylib0", "test/src/lib0.zig");
    const lib: *Node = builder.addArchive(allocator, archive_cmd, "lib1", &.{ obj2, obj3, obj4 });
    const fmt: *Node = builder.addFormat(allocator, format_cmd, "fmt0", "test/src");
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
    try builtin.expect(Node.executeToplevel(&address_space, &thread_space, &allocator, toplevel, t1, .archive));
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try testManyCompileOptionsWithArguments(args, vars);
    testConfigValues();
}
