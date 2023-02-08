const std = @import("std");
const build = std.build;

const util = @import("./util.zig");

const small = .{ .build_mode = .ReleaseSmall };

// PROGRAM FILES ///////////////////////////////////////////////////////////////
pub fn main(builder: *build.Builder) !void {
    util.Context.init(builder);
    // Minor test programs:
    _ = util.addProjectExecutable(builder, "builtin_test", "top/builtin-test.zig", .{ .build_root = true, .runtime_assertions = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "meta_test", "top/meta-test.zig", .{ .runtime_assertions = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "mem_test", "top/mem-test.zig", .{ .runtime_assertions = true, .is_verbose = true, .strip = true });
    _ = util.addProjectExecutable(builder, "algo_test", "top/algo-test.zig", .{ .build_mode = .ReleaseFast, .runtime_assertions = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "file_test", "top/file-test.zig", .{ .runtime_assertions = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "list_test", "top/list-test.zig", .{ .runtime_assertions = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "fmt_test", "top/fmt-test.zig", .{ .build_mode = .Debug, .runtime_assertions = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "render_test", "top/render-test.zig", .{ .runtime_assertions = true, .is_verbose = true });
    _ = util.addProjectExecutable(builder, "parse_test", "top/parse-test.zig", .{ .runtime_assertions = true, .is_verbose = true, .is_test = false });
    _ = util.addProjectExecutable(builder, "proc_test", "top/proc-test.zig", .{ .runtime_assertions = true, .is_verbose = true, .is_test = false });
    _ = util.addProjectExecutable(builder, "thread_test", "top/thread-test.zig", .{ .is_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "virtual_test", "top/virtual-test.zig", .{ .runtime_assertions = true, .is_verbose = true });
    // More complete test programs:
    _ = util.addProjectExecutable(builder, "mca", "test/mca.zig", .{ .build_mode = .ReleaseFast, .runtime_assertions = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "treez", "test/treez.zig", .{ .build_mode = .ReleaseSmall, .runtime_assertions = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "itos", "test/itos.zig", .{ .build_mode = .ReleaseSmall, .runtime_assertions = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "cat", "test/cat.zig", .{ .build_mode = .ReleaseFast, .runtime_assertions = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "hello", "test/hello.zig", .{ .build_mode = .ReleaseSmall, .runtime_assertions = false, .is_verbose = false });
    _ = util.addProjectExecutable(builder, "readelf", "test/readelf.zig", .{ .build_root = true });
    _ = util.addProjectExecutable(builder, "parsedir", "test/parsedir.zig", .{ .build_mode = .ReleaseFast, .build_root = true });
    _ = util.addProjectExecutable(builder, "pathsplit", "test/pathsplit.zig", .{ .build_root = true });
    _ = util.addProjectExecutable(builder, "print_all", "test/print_all_decls.zig", .{ .is_large_test = true, .build_root = true });
    // Other test programs:
    _ = util.addProjectExecutable(builder, "impl_test", "top/impl-test.zig", .{ .is_large_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "container_test", "top/container-test.zig", .{ .is_large_test = true, .build_root = true });
    // Examples
    _ = util.addProjectExecutable(builder, "readdir", "examples/iterate_dir_entries.zig", small);
    _ = util.addProjectExecutable(builder, "dynamic", "examples/dynamic_alloc.zig", .{});
    // Generators:
    _ = util.addProjectExecutable(builder, "build_gen", "top/build-gen.zig", .{ .build_mode = .ReleaseSmall });

    // Memory implementation:
    const mem_gen = builder.step("mem_gen", "generate containers according to specification");
    {
        const spec_to_abstract = util.addProjectExecutable(builder, "spec_to_abstract", "top/mem/spec_to_abstract.zig", small);
        const spec_to_detail = util.addProjectExecutable(builder, "spec_to_detail", "top/mem/spec_to_detail.zig", small);
        const spec_to_options = util.addProjectExecutable(builder, "spec_to_options", "top/mem/spec_to_options.zig", small);
        const abstract_to_type_spec = util.addProjectExecutable(builder, "abstract_to_type_spec", "top/mem/abstract_to_type_spec.zig", small);
        abstract_to_type_spec.step.dependOn(&spec_to_options.run().step);
        abstract_to_type_spec.step.dependOn(&spec_to_abstract.run().step);
        // const detail_to_options = util.addProjectExecutable(builder, "detail_to_options", "top/mem/detail_to_options.zig", small);
        abstract_to_type_spec.step.dependOn(&spec_to_detail.run().step);
        const detail_to_variants = util.addProjectExecutable(builder, "detail_to_variants", "top/mem/detail_to_variants.zig", small);
        detail_to_variants.step.dependOn(&spec_to_detail.run().step);
        detail_to_variants.step.dependOn(&abstract_to_type_spec.run().step);
        const generate_canonical = util.addProjectExecutable(builder, "generate_canonical", "top/mem/generate_canonical.zig", small);
        generate_canonical.step.dependOn(&detail_to_variants.run().step);
        const variants_to_canonicals = util.addProjectExecutable(builder, "variants_to_canonicals", "top/mem/variants_to_canonicals.zig", small);
        variants_to_canonicals.step.dependOn(&generate_canonical.run().step);
        const map_to_containers = util.addProjectExecutable(builder, "map_to_containers", "top/mem/map_to_containers.zig", small);
        map_to_containers.step.dependOn(&variants_to_canonicals.run().step);
        const map_to_specifications = util.addProjectExecutable(builder, "map_to_specifications", "top/mem/map_to_specifications.zig", small);
        map_to_specifications.step.dependOn(&map_to_containers.run().step);

        const generate_references = util.addProjectExecutable(builder, "generate_references", "top/mem/generate_references.zig", .{});
        generate_references.step.dependOn(&map_to_specifications.run().step);

        // mem_gen.dependOn(&detail_to_options.run().step);
        mem_gen.dependOn(&generate_references.run().step);
    }
}
