const _ = struct {
    pub const build = if (true) @import("build/build-aux.zig").main else main;
};
pub usingnamespace @"_";

pub const srg = @import("./zig_lib.zig");
const mem = srg.mem;
const meta = srg.meta;
const preset = srg.preset;
const build = srg.build;
const builtin = srg.builtin;

const modules = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};

const minor_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .modules = modules,
};
const algo_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .build_mode = .ReleaseSmall,
    .modules = modules,
};
const fmt_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .modules = modules,
};
const fast_test_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseFast,
    .modules = modules,
};
const small_test_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseSmall,
    .modules = modules,
};
const lib_parser_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_lib_macros,
    .modules = modules,
};
const std_parser_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_std_macros,
    .modules = modules,
};
const parsedir_std_macros: []const build.Macro = meta.slice(build.Macro, .{.{
    .name = "test_subject",
    .value = .{ .string = "std" },
}});
const parsedir_lib_macros: []const build.Macro = meta.slice(build.Macro, .{.{
    .name = "test_subject",
    .value = .{ .string = "lib" },
}});

// TODO Create super type for build options permitting the creation of
// dependencies, etc. Like step.
// zig fmt: off
pub fn main(builder: *build.Builder) !void {
    // Top test programs
    const builtin_test: *build.Target   = builder.addExecutable("builtin_test",   "top/builtin-test.zig", minor_test_args);
    const meta_test: *build.Target      = builder.addExecutable("meta_test",      "top/meta-test.zig",    minor_test_args);
    const mem_test: *build.Target       = builder.addExecutable("mem_test",       "top/mem-test.zig",     minor_test_args);
    const algo_test: *build.Target      = builder.addExecutable("algo_test",      "top/algo-test.zig",    algo_test_args);
    const file_test: *build.Target      = builder.addExecutable("file_test",      "top/file-test.zig",    minor_test_args);
    const list_test: *build.Target      = builder.addExecutable("list_test",      "top/list-test.zig",    minor_test_args);
    const fmt_test: *build.Target       = builder.addExecutable("fmt_test",       "top/fmt-test.zig",     fmt_test_args);
    const render_test: *build.Target    = builder.addExecutable("render_test",    "top/render-test.zig",  minor_test_args);
    const thread_test: *build.Target    = builder.addExecutable("thread_test",    "top/thread-test.zig",  minor_test_args);
    const virtual_test: *build.Target   = builder.addExecutable("virtual_test",   "top/virtual-test.zig", minor_test_args);
    const build_test: *build.Target     = builder.addExecutable("build_test",     "top/build-test.zig",   small_test_args);
    for (.{ builtin_test, meta_test, mem_test, algo_test, file_test, list_test, fmt_test, render_test, thread_test, virtual_test, build_test }) |_| {}

    // More complete test programs:
    const mca: *build.Target            = builder.addExecutable("mca",            "test/mca.zig",         fast_test_args);
    const treez: *build.Target          = builder.addExecutable("treez",          "test/treez.zig",       small_test_args);
    const itos: *build.Target           = builder.addExecutable("itos",           "test/itos.zig",        small_test_args);
    const cat: *build.Target            = builder.addExecutable("cat",            "test/cat.zig",         fast_test_args);
    const hello: *build.Target          = builder.addExecutable("hello",          "test/hello.zig",       small_test_args);
    const readelf: *build.Target        = builder.addExecutable("readelf",        "test/readelf.zig",     minor_test_args);
    const parsedir: *build.Target       = builder.addExecutable("parsedir",       "test/parsedir.zig",    fast_test_args);
    for (.{ mca, treez, itos, cat, hello, readelf, parsedir }) |_| {}

    // Other test programs:
    const impl_test: *build.Target          = builder.addExecutable("impl_test",      "top/impl-test.zig",        .{});
    const container_test: *build.Target     = builder.addExecutable("container_test", "top/container-test.zig",   .{});
    const parse_test: *build.Target         = builder.addExecutable("parse_test",     "top/parse-test.zig",       .{});
    const lib_parser_test: *build.Target    = builder.addExecutable("lib_parser",     "test/parsedir.zig",        lib_parser_args);
    const std_parser_test: *build.Target    = builder.addExecutable("std_parser",     "test/parsedir.zig",        std_parser_args);
    for (.{ impl_test, container_test, parse_test, lib_parser_test, std_parser_test }) |_| {}

    // Examples
    const readdir: *build.Target            = builder.addExecutable("readdir",        "examples/iterate_dir_entries.zig",     small_test_args);
    const dynamic: *build.Target            = builder.addExecutable("dynamic",        "examples/dynamic_alloc.zig",           small_test_args);
    const address_space: *build.Target      = builder.addExecutable("address_space",  "examples/custom_address_space.zig",    small_test_args);
    for (.{ readdir, dynamic, address_space }) |_| {}

}
