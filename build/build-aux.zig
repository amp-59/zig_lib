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
    _ = util.addProjectExecutable(builder, "generate_build", "top/build/generate_build.zig", .{ .build_mode = .ReleaseSmall });

    // Memory implementation:
    const mem_gen = builder.step("mem_gen", "generate containers according to specification");
    {
        const default = .{ .build_mode = .ReleaseSmall };
        const expr_test = util.addProjectExecutable(builder, "expr_test", "top/mem/expr-test.zig", default);
        const abstract_params = util.addProjectExecutable(builder, "mg_abstract_params", "top/mem/abstract_params-aux.zig", default);
        const impl_detail = util.addProjectExecutable(builder, "mg_impl_detail", "top/mem/impl_detail-aux.zig", default);
        const options = util.addProjectExecutable(builder, "mg_options", "top/mem/options-aux.zig", default);
        const type_specs = util.addProjectExecutable(builder, "mg_type_specs", "top/mem/type_specs-aux.zig", default);
        const type_descr = util.addProjectExecutable(builder, "mg_type_descr", "top/mem/type_descr-aux.zig", default);
        const impl_variants = util.addProjectExecutable(builder, "mg_impl_variants", "top/mem/impl_variants-aux.zig", default);
        const canonical = util.addProjectExecutable(builder, "mg_canonical", "top/mem/canonical-aux.zig", default);
        const canonicals = util.addProjectExecutable(builder, "mg_canonicals", "top/mem/canonicals-aux.zig", default);
        const containers = util.addProjectExecutable(builder, "mg_containers", "top/mem/containers-aux.zig", default);
        const kinds = util.addProjectExecutable(builder, "mg_kinds", "top/mem/kinds-aux.zig", default);
        const specifications = util.addProjectExecutable(builder, "mg_specifications", "top/mem/specifications-aux.zig", default);
        const generate_functions = util.addProjectExecutable(builder, "generate_functions", "top/mem/generate_functions.zig", default);
        const generate_specifications = util.addProjectExecutable(builder, "generate_specifications", "top/mem/generate_specifications.zig", default);
        const generate_references = util.addProjectExecutable(builder, "generate_references", "top/mem/generate_references.zig", default);
        const generate_parameters = util.addProjectExecutable(builder, "generate_parameters", "top/mem/generate_parameters.zig", default);
        const generate_containers = util.addProjectExecutable(builder, "generate_containers", "top/mem/generate_containers.zig", default);
        dependOn(type_specs, abstract_params);
        dependOn(type_descr, type_specs);
        dependOn(impl_variants, type_specs);
        dependOn(impl_variants, impl_detail);
        dependOn(canonicals, impl_variants);
        dependOn(canonicals, canonical);
        dependOn(containers, canonicals);
        dependOn(kinds, canonicals);
        dependOn(generate_functions, impl_variants);
        dependOn(generate_functions, expr_test);
        dependOn(specifications, containers);
        dependOn(generate_specifications, options);
        dependOn(generate_specifications, type_descr);
        dependOn(generate_specifications, specifications);
        dependOn(generate_references, containers);
        dependOn(generate_references, generate_specifications);
        dependOn(generate_parameters, options);
        dependOn(generate_parameters, type_descr);
        dependOn(generate_parameters, containers);
        dependOn(generate_containers, generate_parameters);
        mem_gen.dependOn(&generate_references.run().step);
        mem_gen.dependOn(&generate_containers.run().step);
    }
}
inline fn dependOn(dependant: *build.CompileStep, dependency: *build.CompileStep) void {
    dependant.step.dependOn(&dependency.run().step);
}
