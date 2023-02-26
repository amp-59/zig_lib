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
    _ = util.addProjectExecutable(builder, "size_per_config", "test/size_per_config.zig", .{ .build_root = true });
    _ = util.addProjectExecutable(builder, "print_all", "test/print_all_decls.zig", .{ .is_large_test = true, .build_root = true });
    // Other test programs:
    _ = util.addProjectExecutable(builder, "impl_test", "top/impl-test.zig", .{ .is_large_test = true, .build_root = true });
    _ = util.addProjectExecutable(builder, "build_test", "top/build-test.zig", .{ .build_root = true, .build_mode = .Debug });
    _ = util.addProjectExecutable(builder, "container_test", "top/container-test.zig", .{ .is_large_test = true, .build_root = true });
    // Examples
    _ = util.addProjectExecutable(builder, "readdir", "examples/iterate_dir_entries.zig", small);
    _ = util.addProjectExecutable(builder, "dynamic", "examples/dynamic_alloc.zig", .{});
    _ = util.addProjectExecutable(builder, "sortfile", "examples/sortfile.zig", .{ .build_mode = .ReleaseFast });
    _ = util.addProjectExecutable(builder, "allocators", "examples/allocators.zig", .{ .build_mode = .ReleaseSmall });
    // Generators:
    _ = util.addProjectExecutable(builder, "build_gen", "top/build-gen.zig", .{ .build_mode = .ReleaseSmall });

    // Memory implementation:
    const mem_gen = builder.step("mem_gen", "generate containers according to specification");
    {
        const default = .{ .build_mode = .ReleaseSmall };
        const expr_test = util.addProjectExecutable(builder, "expr_test", "top/mem/expr-test.zig", .{});

        const spec_to_abstract = util.addProjectExecutable(builder, "spec_to_abstract", "top/mem/spec_to_abstract.zig", default);
        const spec_to_detail = util.addProjectExecutable(builder, "spec_to_detail", "top/mem/spec_to_detail.zig", default);
        const spec_to_options = util.addProjectExecutable(builder, "spec_to_options", "top/mem/spec_to_options.zig", default);
        const abstract_to_type_spec = util.addProjectExecutable(builder, "abstract_to_type_specs", "top/mem/abstract_to_type_specs.zig", default);
        dependOn(abstract_to_type_spec, spec_to_abstract);
        const type_specs_to_type_descrs = util.addProjectExecutable(builder, "type_specs_to_type_descrs", "top/mem/type_specs_to_type_descrs.zig", default);
        dependOn(type_specs_to_type_descrs, abstract_to_type_spec);
        const detail_to_variants = util.addProjectExecutable(builder, "detail_to_variants", "top/mem/detail_to_variants.zig", default);
        dependOn(detail_to_variants, abstract_to_type_spec);
        dependOn(detail_to_variants, spec_to_detail);
        const generate_canonical = util.addProjectExecutable(builder, "generate_canonical", "top/mem/generate_canonical.zig", default);
        const variants_to_canonicals = util.addProjectExecutable(builder, "variants_to_canonicals", "top/mem/variants_to_canonicals.zig", default);
        dependOn(variants_to_canonicals, detail_to_variants);
        dependOn(variants_to_canonicals, generate_canonical);
        const map_to_containers = util.addProjectExecutable(builder, "map_to_containers", "top/mem/map_to_containers.zig", default);
        dependOn(map_to_containers, variants_to_canonicals);
        const map_to_kinds = util.addProjectExecutable(builder, "map_to_kinds", "top/mem/map_to_kinds.zig", default);
        dependOn(map_to_kinds, variants_to_canonicals);
        const variants_to_allocator_functions = util.addProjectExecutable(builder, "variants_to_allocator_functions", "top/mem/variants_to_allocator_functions.zig", default);
        dependOn(variants_to_allocator_functions, detail_to_variants);
        dependOn(variants_to_allocator_functions, expr_test);
        // const variants_to_interfaces = util.addProjectExecutable(builder, "kinds_to_interfaces", "top/mem/kinds_to_interfaces.zig", default);
        // dependOn(variants_to_interfaces, map_to_kinds);
        const map_to_specifications = util.addProjectExecutable(builder, "map_to_specifications", "top/mem/map_to_specifications.zig", default);
        dependOn(map_to_specifications, map_to_containers);
        const generate_specifications = util.addProjectExecutable(builder, "generate_specifications", "top/mem/generate_specifications.zig", default);
        dependOn(generate_specifications, spec_to_options);
        dependOn(generate_specifications, type_specs_to_type_descrs);
        dependOn(generate_specifications, map_to_specifications);
        const generate_references = util.addProjectExecutable(builder, "generate_references", "top/mem/generate_references.zig", default);
        dependOn(generate_references, map_to_containers);
        dependOn(generate_references, generate_specifications);
        const generate_parameters = util.addProjectExecutable(builder, "generate_parameters", "top/mem/generate_parameters.zig", default);
        dependOn(generate_parameters, spec_to_options);
        dependOn(generate_parameters, type_specs_to_type_descrs);
        dependOn(generate_parameters, map_to_containers);
        const generate_containers = util.addProjectExecutable(builder, "generate_containers", "top/mem/generate_containers.zig", default);
        dependOn(generate_containers, generate_parameters);
        // const generate_allocators = util.addProjectExecutable(builder, "generate_allocators", "top/mem/generate_allocators.zig", default);
        // dependOn(generate_allocators, map_to_kinds);
        // dependOn(generate_allocators, variants_to_interfaces);

        mem_gen.dependOn(&generate_references.run().step);
        mem_gen.dependOn(&generate_containers.run().step);
        // mem_gen.dependOn(&generate_allocators.run().step);
    }
}
inline fn dependOn(dependant: *build.CompileStep, dependency: *build.CompileStep) void {
    dependant.step.dependOn(&dependency.run().step);
}
