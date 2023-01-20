const std = @import("std");
const build = std.build;

const util = @import("./util.zig");

// PROGRAM FILES ///////////////////////////////////////////////////////////////

pub fn main(builder: *build.Builder) !void {
    util.Context.init(builder);

    // Minor test programs:
    _ = util.addProjectExecutable(builder, "builtin_test", "top/builtin-test.zig", .{ .build_root = true, .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "meta_test", "top/meta-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "mem_test", "top/mem-test.zig", .{ .is_correct = true, .is_verbose = true, .strip = true });
    _ = util.addProjectExecutable(builder, "algo_test", "top/algo-test.zig", .{ .build_mode = .ReleaseSmall, .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "file_test", "top/file-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "list_test", "top/list-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "fmt_test", "top/fmt-test.zig", .{ .build_mode = .Debug, .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "render_test", "top/render-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "parse_test", "top/parse-test.zig", .{ .is_correct = true, .is_verbose = true, .is_test = false });
    _ = util.addProjectExecutable(builder, "thread_test", "top/thread-test.zig", .{ .is_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "virtual_test", "top/virtual-test.zig", .{ .is_correct = true, .is_verbose = true });

    // More complete test programs:
    _ = util.addProjectExecutable(builder, "buildgen", "test/buildgen.zig", .{ .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "mca", "test/mca.zig", .{ .build_mode = .ReleaseFast, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "treez", "test/treez.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "itos", "test/itos.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "cat", "test/cat.zig", .{ .build_mode = .ReleaseFast, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "hello", "test/hello.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "readelf", "test/readelf.zig", .{ .build_root = true });
    _ = util.addProjectExecutable(builder, "parsedir", "test/parsedir.zig", .{ .build_mode = .ReleaseFast, .build_root = true });
    _ = util.addProjectExecutable(builder, "pathsplit", "test/pathsplit.zig", .{ .build_root = true });

    // Other test programs:
    _ = util.addProjectExecutable(builder, "impl_test", "top/impl-test.zig", .{ .is_large_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "container_test", "top/container-test.zig", .{ .is_large_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "builder_test", "top/builder-test.zig", .{ .is_large_test = true, .build_root = true });

    // Examples
    _ = util.addProjectExecutable(builder, "readdir", "examples/iterate_dir_entries.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "dynamic", "examples/dynamic_alloc.zig", .{ .is_correct = true, .is_verbose = true });
}
