const zig_lib = @import("../zig_lib.zig");

const proc = zig_lib.proc;
const spec = zig_lib.spec;
const meta = zig_lib.meta;
const build = zig_lib.build;
const builtin = zig_lib.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = false;

const Builder = build.GenericBuilder(spec.builder.default);

fn buildMain(allocator: *Builder.Allocator, builder: *Builder) !void {
    const g0: *Builder.Group = try builder.addGroup(allocator, "g0");
    const t0: *Builder.Target = try g0.addTarget(allocator, .{ .build = .{
        .kind = .exe,
        .allow_shlib_undefined = true,
        .build_id = true,
        .cflags = &.{"-O3"},
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
    } }, "target", @src().file);
    t0.descr = "Dummy target";
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: Builder.Allocator = try meta.wrap(
        Builder.Allocator.init(&address_space, Builder.max_thread_count),
    );
    defer allocator.deinit(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try buildMain(&allocator, &builder);
    builder.grps[0].trgs[0].executeToplevel(&address_space, &thread_space, &allocator, &builder, .build);
}
