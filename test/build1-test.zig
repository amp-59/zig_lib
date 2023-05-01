const zig_lib = @import("../zig_lib.zig");

const proc = zig_lib.proc;
const spec = zig_lib.spec;
const meta = zig_lib.meta;
const build = zig_lib.build;
const builtin = zig_lib.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

const Builder = build.GenericBuilder(spec.builder.default);

fn buildMain(allocator: *Builder.Allocator, builder: *Builder) !void {
    const g0: *Builder.Group = try builder.addGroup(allocator, "g0");
    const t0: *Builder.Target = try g0.addTarget(allocator, .{}, "target", @src().file);

    t0.build_cmd.allow_shlib_undefined = true;
    t0.build_cmd.build_id = true;
    t0.build_cmd.cflags = &.{"-O3"};
    t0.build_cmd.clang = true;
    t0.build_cmd.code_model = .default;
    t0.build_cmd.color = .auto;
    t0.build_cmd.compiler_rt = false;
    t0.build_cmd.compress_debug_sections = true;
    t0.build_cmd.cpu = "x86_64";
    t0.build_cmd.dynamic = true;
    t0.build_cmd.dirafter = "after";
    t0.build_cmd.dynamic_linker = "/usr/bin/ld";
    t0.build_cmd.library_directory = &.{ "/usr/lib64", "/usr/lib32" };
    t0.build_cmd.mode = .Debug;
    t0.build_cmd.strip = true;

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
