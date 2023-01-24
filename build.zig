pub const build = if (true) @import("build/build-aux.zig").main else main;
pub const srg = @import("./zig_lib.zig");
const mem = srg.mem;
const meta = srg.meta;
const preset = srg.preset;
const builder = srg.builder;
const builtin = srg.builtin;

const packages = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};

const minor_test_args = .{
    .is_correct = true,
    .is_verbose = true,
    .packages = packages,
};
const algo_test_args = .{
    .is_correct = true,
    .is_verbose = true,
    .build_mode = .ReleaseSmall,
    .packages = packages,
};
const fmt_test_args = .{
    .is_correct = true,
    .is_verbose = true,
    .packages = packages,
};
const fast_test_args = .{
    .is_correct = false,
    .is_verbose = false,
    .build_mode = .ReleaseFast,
    .packages = packages,
};
const small_test_args = .{
    .is_correct = false,
    .is_verbose = false,
    .build_mode = .ReleaseSmall,
    .packages = packages,
};
const lib_parser_args = .{
    .is_correct = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_lib_macros,
    .packages = packages,
};
const std_parser_args = .{
    .is_correct = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_std_macros,
    .packages = packages,
};
const parsedir_std_macros: builder.Macros = meta.slice(builder.Macro, .{.{ .name = "test_subject", .value = "\"std\"" }});
const parsedir_lib_macros: builder.Macros = meta.slice(builder.Macro, .{.{ .name = "test_subject", .value = "\"lib\"" }});

pub fn main(ctx: *builder.Context) !void {
    // Top test programs:
    _ = ctx.addExecutable("builtin_test", "top/builtin-test.zig", minor_test_args);
    _ = ctx.addExecutable("meta_test", "top/meta-test.zig", minor_test_args);
    _ = ctx.addExecutable("mem_test", "top/mem-test.zig", minor_test_args);
    _ = ctx.addExecutable("algo_test", "top/algo-test.zig", algo_test_args);
    _ = ctx.addExecutable("file_test", "top/file-test.zig", minor_test_args);
    _ = ctx.addExecutable("list_test", "top/list-test.zig", minor_test_args);
    _ = ctx.addExecutable("fmt_test", "top/fmt-test.zig", fmt_test_args);
    _ = ctx.addExecutable("render_test", "top/render-test.zig", minor_test_args);
    _ = ctx.addExecutable("thread_test", "top/thread-test.zig", minor_test_args);
    _ = ctx.addExecutable("virtual_test", "top/virtual-test.zig", minor_test_args);

    // More complete test programs:
    _ = ctx.addExecutable("mca", "test/mca.zig", fast_test_args);
    _ = ctx.addExecutable("treez", "test/treez.zig", small_test_args);
    _ = ctx.addExecutable("itos", "test/itos.zig", small_test_args);
    _ = ctx.addExecutable("cat", "test/cat.zig", fast_test_args);
    _ = ctx.addExecutable("hello", "test/hello.zig", small_test_args);
    _ = ctx.addExecutable("readelf", "test/readelf.zig", minor_test_args);
    _ = ctx.addExecutable("parsedir", "test/parsedir.zig", fast_test_args);

    // Other test programs:
    _ = ctx.addExecutable("impl_test", "top/impl-test.zig", .{});
    _ = ctx.addExecutable("container_test", "top/container-test.zig", .{});
    _ = ctx.addExecutable("parse_test", "top/parse-test.zig", .{});

    _ = ctx.addExecutable("lib_parser", "./test/parsedir.zig", lib_parser_args);
    _ = ctx.addExecutable("std_parser", "./test/parsedir.zig", std_parser_args);

    // Examples
    _ = ctx.addExecutable("readdir", "examples/iterate_dir_entries.zig", small_test_args);
    _ = ctx.addExecutable("dynamic", "./examples/dynamic_alloc.zig", small_test_args);
    _ = ctx.addExecutable("address_space", "./examples/custom_address_space.zig", small_test_args);

    // Generators:
    // _ = ctx.addExecutable("builder_gen", "top/builder-gen.zig", small_test_args);
}
