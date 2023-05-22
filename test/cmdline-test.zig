const zig_lib = @import("../zig_lib.zig");

const mem = zig_lib.mem;
const proc = zig_lib.proc;
const spec = zig_lib.spec;
const meta = zig_lib.meta;
const build = zig_lib.build;
const builtin = zig_lib.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = true;

const Builder = build.GenericBuilder(.{
    .logging = spec.builder.logging.verbose,
    .errors = spec.builder.errors.noexcept,
    .options = .{ .max_cmdline_len = null },
});
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: Builder.Allocator = if (Builder.Allocator == mem.SimpleAllocator)
        Builder.Allocator.init_arena(Builder.AddressSpace.arena(Builder.max_thread_count))
    else
        Builder.Allocator.init(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    const g0: *Builder.Group = try builder.addGroup(&allocator, "g0");
    const t0: *Builder.Target = try g0.addBuild(&allocator, .{
        .kind = .obj,
        .allow_shlib_undefined = true,
        .build_id = true,
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
    }, .{ .name = "target", .root = @src().file, .descr = "Dummy target" });
    const t1: *Builder.Target = try g0.addArchive(&allocator, .{
        .operation = .r,
        .create = true,
    }, .{ .root = "zig-out/lib/archive.a" }, &.{t0});
    Builder.debug.builderCommandNotice(&builder, true, true, true);
    t1.executeToplevel(&address_space, &thread_space, &allocator, &builder, .archive);
}
