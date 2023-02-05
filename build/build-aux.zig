const std = @import("std");
const build = std.build;

const util = @import("./util.zig");

// PROGRAM FILES ///////////////////////////////////////////////////////////////

fn memoryImplementation(builder: *build.Builder) void {
    const stage_3_products: [1][]const u8 = .{
        "top/mem/reference.zig",
    };

    const mem_gen = builder.step("mem_gen", "generate containers according to specification");
    const mem_gen_0 = util.addProjectExecutable(builder, "mem_gen_0", "top/mem/gen-0-aux.zig", .{ .build_mode = .ReleaseSmall });
    const mem_gen_1 = util.addProjectExecutable(builder, "mem_gen_1", "top/mem/gen-1-aux.zig", .{ .build_mode = .ReleaseSmall });
    const mem_gen_2 = util.addProjectExecutable(builder, "mem_gen_2", "top/mem/gen-2-aux.zig", .{ .build_mode = .ReleaseSmall });
    const mem_gen_3 = util.addProjectExecutable(builder, "mem_gen_3", "top/mem/gen-3-aux.zig", .{ .build_mode = .ReleaseSmall });
    const mem_gen_4 = util.addProjectExecutable(builder, "mem_gen_4", "top/mem/gen-4-aux.zig", .{ .build_mode = .ReleaseSmall });
    const mem_gen_5 = util.addProjectExecutable(builder, "mem_gen_5", "top/mem/gen-5-aux.zig", .{ .build_mode = .ReleaseSmall });

    mem_gen_1.step.dependOn(&mem_gen_0.run().step);
    mem_gen_2.step.dependOn(&mem_gen_1.run().step);
    mem_gen_3.step.dependOn(&mem_gen_2.run().step);
    mem_gen_4.step.dependOn(&mem_gen_3.run().step);
    mem_gen_4.step.dependOn(&builder.addFmt(&stage_3_products).step);
    mem_gen_5.step.dependOn(&mem_gen_2.run().step);
    mem_gen.dependOn(&mem_gen_4.run().step);

    const spec_to_abstract = util.addProjectExecutable(builder, "spec_to_abstract", "top/mem/spec_to_abstract.zig", .{ .build_mode = .ReleaseSmall });
    _ = spec_to_abstract;
    const spec_to_detail = util.addProjectExecutable(builder, "spec_to_detail", "top/mem/spec_to_detail.zig", .{ .build_mode = .ReleaseSmall });
    _ = spec_to_detail;
    const spec_to_options = util.addProjectExecutable(builder, "spec_to_options", "top/mem/spec_to_options.zig", .{ .build_mode = .ReleaseSmall });
    _ = spec_to_options;
    const abstract_to_type_spec = util.addProjectExecutable(builder, "abstract_to_type_spec", "top/mem/abstract_to_type_spec.zig", .{ .build_mode = .ReleaseSmall });
    _ = abstract_to_type_spec;
    const detail_to_options = util.addProjectExecutable(builder, "detail_to_specifiers", "top/mem/detail_to_specifiers.zig", .{ .build_mode = .ReleaseSmall });
    _ = detail_to_options;
    const detail_to_groups = util.addProjectExecutable(builder, "detail_to_groups", "top/mem/detail_to_groups.zig", .{ .build_mode = .ReleaseSmall });
    _ = detail_to_groups;
    const detail_to_variants = util.addProjectExecutable(builder, "detail_to_variants", "top/mem/detail_to_variants.zig", .{ .build_mode = .ReleaseSmall });
    _ = detail_to_variants;
}

pub fn main(builder: *build.Builder) !void {
    util.Context.init(builder);
    // Minor test programs:
    _ = util.addProjectExecutable(builder, "builtin_test", "top/builtin-test.zig", .{ .build_root = true, .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "meta_test", "top/meta-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "mem_test", "top/mem-test.zig", .{ .is_correct = true, .is_verbose = true, .strip = true });
    _ = util.addProjectExecutable(builder, "algo_test", "top/algo-test.zig", .{ .build_mode = .ReleaseFast, .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "file_test", "top/file-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "list_test", "top/list-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "fmt_test", "top/fmt-test.zig", .{ .build_mode = .Debug, .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "render_test", "top/render-test.zig", .{ .is_correct = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "parse_test", "top/parse-test.zig", .{ .is_correct = true, .is_verbose = true, .is_test = false });
    _ = util.addProjectExecutable(builder, "proc_test", "top/proc-test.zig", .{ .is_correct = true, .is_verbose = true, .is_test = false });
    _ = util.addProjectExecutable(builder, "thread_test", "top/thread-test.zig", .{ .is_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "virtual_test", "top/virtual-test.zig", .{ .is_correct = true, .is_verbose = true });
    // More complete test programs:
    _ = util.addProjectExecutable(builder, "mca", "test/mca.zig", .{ .build_mode = .ReleaseFast, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "treez", "test/treez.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "itos", "test/itos.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "cat", "test/cat.zig", .{ .build_mode = .ReleaseFast, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "hello", "test/hello.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "readelf", "test/readelf.zig", .{ .build_root = true });
    _ = util.addProjectExecutable(builder, "parsedir", "test/parsedir.zig", .{ .build_mode = .ReleaseFast, .build_root = true });
    _ = util.addProjectExecutable(builder, "pathsplit", "test/pathsplit.zig", .{ .build_root = true });
    _ = util.addProjectExecutable(builder, "print_all", "test/print_all_decls.zig", .{ .is_large_test = true, .build_root = true });
    // Other test programs:
    _ = util.addProjectExecutable(builder, "impl_test", "top/impl-test.zig", .{ .is_large_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "container_test", "top/container-test.zig", .{ .is_large_test = true, .build_root = true });
    // Examples
    _ = util.addProjectExecutable(builder, "readdir", "examples/iterate_dir_entries.zig", .{ .build_mode = .ReleaseSmall });
    _ = util.addProjectExecutable(builder, "restack", "examples/remap_stack.zig", .{});
    _ = util.addProjectExecutable(builder, "dynamic", "examples/dynamic_alloc.zig", .{});
    // Generators:
    _ = util.addProjectExecutable(builder, "builder_gen", "top/builder-gen.zig", .{ .build_mode = .ReleaseSmall });
    memoryImplementation(builder);
}
