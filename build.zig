const _ = struct {
    pub const build = if (true) @import("build/build-aux.zig").main else main;
};
pub const srg = @import("./zig_lib.zig");
pub usingnamespace @"_";
const mem = srg.mem;
const meta = srg.meta;
const preset = srg.preset;
const build = srg.build;
const builtin = srg.builtin;

const packages = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};

const minor_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .packages = packages,
};
const algo_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .build_mode = .ReleaseSmall,
    .packages = packages,
};
const fmt_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .packages = packages,
};
const fast_test_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseFast,
    .packages = packages,
};
const small_test_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseSmall,
    .packages = packages,
};
const lib_parser_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_lib_macros,
    .packages = packages,
};
const std_parser_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_std_macros,
    .packages = packages,
};
const parsedir_std_macros: build.Macros = meta.slice(build.Macro, .{.{ .name = "test_subject", .value = .{ .string = "std" } }});
const parsedir_lib_macros: build.Macros = meta.slice(build.Macro, .{.{ .name = "test_subject", .value = .{ .string = "lib" } }});

// zig fmt: off

fn memgen(builder: *build.Builder) !void {
    _ = builder;
}
// TODO Create super type for build options permitting the creation of
// dependencies, etc. Like step.
pub fn main(builder: *build.Builder) !void {
    // Top test programs
    _ = builder.addExecutable("builtin_test",   "top/builtin-test.zig", minor_test_args);
    _ = builder.addExecutable("meta_test",      "top/meta-test.zig",    minor_test_args);
    _ = builder.addExecutable("mem_test",       "top/mem-test.zig",     minor_test_args);
    _ = builder.addExecutable("algo_test",      "top/algo-test.zig",    algo_test_args);
    _ = builder.addExecutable("file_test",      "top/file-test.zig",    minor_test_args);
    _ = builder.addExecutable("list_test",      "top/list-test.zig",    minor_test_args);
    _ = builder.addExecutable("fmt_test",       "top/fmt-test.zig",     fmt_test_args);
    _ = builder.addExecutable("render_test",    "top/render-test.zig",  minor_test_args);
    _ = builder.addExecutable("thread_test",    "top/thread-test.zig",  minor_test_args);
    _ = builder.addExecutable("virtual_test",   "top/virtual-test.zig", minor_test_args);
    _ = builder.addExecutable("build_test",   "top/build-test.zig", minor_test_args);
    // More complete test programs:
    _ = builder.addExecutable("mca",            "test/mca.zig",         fast_test_args);
    _ = builder.addExecutable("treez",          "test/treez.zig",       small_test_args);
    _ = builder.addExecutable("itos",           "test/itos.zig",        small_test_args);
    _ = builder.addExecutable("cat",            "test/cat.zig",         fast_test_args);
    _ = builder.addExecutable("hello",          "test/hello.zig",       small_test_args);
    _ = builder.addExecutable("readelf",        "test/readelf.zig",     minor_test_args);
    _ = builder.addExecutable("parsedir",       "test/parsedir.zig",    fast_test_args);
    // Other test programs:
    _ = builder.addExecutable("impl_test",      "top/impl-test.zig",        .{});
    _ = builder.addExecutable("container_test", "top/container-test.zig",   .{});
    _ = builder.addExecutable("parse_test",     "top/parse-test.zig",       .{});
    _ = builder.addExecutable("lib_parser",     "test/parsedir.zig",        lib_parser_args);
    _ = builder.addExecutable("std_parser",     "test/parsedir.zig",        std_parser_args);
    // Examples
    _ = builder.addExecutable("readdir",        "examples/iterate_dir_entries.zig",     small_test_args);
    _ = builder.addExecutable("dynamic",        "examples/dynamic_alloc.zig",           small_test_args);
    _ = builder.addExecutable("address_space",  "examples/custom_address_space.zig",    small_test_args);

    // Generators:
    try memgen(builder);
}
