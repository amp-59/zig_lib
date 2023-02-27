const _ = struct {
    pub const build = if (false) @import("build/build-aux.zig").main else main;
};
pub usingnamespace @"_";

pub const srg = @import("./zig_lib.zig");
const mem = srg.mem;
const meta = srg.meta;
const preset = srg.preset;
const build = srg.build;
const builtin = srg.builtin;

const modules = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};
const deps = &.{"zig_lib"};

const minor_test_spec: build.TargetSpec = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .modules = modules,
    .deps = deps,
};
const algo_test_spec: build.TargetSpec = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .build_mode = .ReleaseSmall,
    .modules = modules,
    .deps = deps,
};
const fmt_test_spec: build.TargetSpec = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .modules = modules,
    .deps = deps,
};
const fast_test_spec: build.TargetSpec = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseFast,
    .modules = modules,
    .deps = deps,
};
const small_test_spec: build.TargetSpec = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseSmall,
    .modules = modules,
    .deps = deps,
};
const small_spec: build.TargetSpec = .{
    .mode = .ReleaseSmall,
    .mods = modules,
    .deps = deps,
};
const lib_parser_spec: build.TargetSpec = .{
    .mode = .ReleaseFast,
    .macros = parsedir_lib_macros,
    .modules = modules,
    .deps = deps,
};
const std_parser_spec: build.TargetSpec = .{
    .build_mode = .ReleaseFast,
    .macros = parsedir_std_macros,
    .modules = modules,
    .deps = deps,
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
pub fn main(allocator: *build.Allocator, builder: *build.Builder) !void {
    // Top test programs
    const builtin_test: *build.Target   = builder.addTarget(.{}, allocator, "builtin_test",   "top/builtin-test.zig");
    const meta_test: *build.Target      = builder.addTarget(.{}, allocator, "meta_test",      "top/meta-test.zig");
    const mem_test: *build.Target       = builder.addTarget(.{}, allocator, "mem_test",       "top/mem-test.zig");
    const algo_test: *build.Target      = builder.addTarget(.{}, allocator, "algo_test",      "top/algo-test.zig");
    const file_test: *build.Target      = builder.addTarget(.{}, allocator, "file_test",      "top/file-test.zig");
    const list_test: *build.Target      = builder.addTarget(.{}, allocator, "list_test",      "top/list-test.zig");
    const fmt_test: *build.Target       = builder.addTarget(.{}, allocator, "fmt_test",       "top/fmt-test.zig");
    const render_test: *build.Target    = builder.addTarget(.{}, allocator, "render_test",    "top/render-test.zig");
    const thread_test: *build.Target    = builder.addTarget(.{}, allocator, "thread_test",    "top/thread-test.zig");
    const virtual_test: *build.Target   = builder.addTarget(.{}, allocator, "virtual_test",   "top/virtual-test.zig");
    const build_test: *build.Target     = builder.addTarget(.{}, allocator, "build_test",     "top/build-test.zig");

    // More complete test programs:
    const mca: *build.Target            = builder.addTarget(.{}, allocator, "mca",            "test/mca.zig");
    const treez: *build.Target          = builder.addTarget(.{}, allocator, "treez",          "test/treez.zig");
    const itos: *build.Target           = builder.addTarget(.{}, allocator, "itos",           "test/itos.zig");
    const cat: *build.Target            = builder.addTarget(.{}, allocator, "cat",            "test/cat.zig");
    const hello: *build.Target          = builder.addTarget(.{}, allocator, "hello",          "test/hello.zig");
    const readelf: *build.Target        = builder.addTarget(.{}, allocator, "readelf",        "test/readelf.zig");
    const parsedir: *build.Target       = builder.addTarget(.{}, allocator, "parsedir",       "test/parsedir.zig");
    // Other test programs:
    const impl_test: *build.Target          = builder.addTarget(.{}, allocator, "impl_test",      "top/impl-test.zig");
    const container_test: *build.Target     = builder.addTarget(.{}, allocator, "container_test", "top/container-test.zig");
    const parse_test: *build.Target         = builder.addTarget(.{}, allocator, "parse_test",     "top/parse-test.zig");
    const lib_parser_test: *build.Target    = builder.addTarget(.{}, allocator, "lib_parser",     "test/parsedir.zig");
    const std_parser_test: *build.Target    = builder.addTarget(.{}, allocator, "std_parser",     "test/parsedir.zig");
    // Examples
    const readdir: *build.Target            = builder.addTarget(.{}, allocator, "readdir",        "examples/iterate_dir_entries.zig");
    const dynamic: *build.Target            = builder.addTarget(.{}, allocator, "dynamic",        "examples/dynamic_alloc.zig");
    const address_space: *build.Target      = builder.addTarget(.{}, allocator, "address_space",  "examples/custom_address_space.zig");

    // Memory implementation generator
    const mg: *build.Group                          = builder.addGroup(allocator, "memgen");
    const mg_aux: *build.Group                      = builder.addGroup(allocator, "memgen_auxiliary");
    {
    // const expr_test: *build.Target                  = mg_aux.addTarget(small_spec, allocator, "expr_test",                 "top/mem/expr-test.zig");
    const abstract_params: *build.Target            = mg_aux.addTarget(small_spec, allocator, "mg_abstract_params",        "top/mem/abstract_params-aux.zig");
    const impl_detail: *build.Target                = mg_aux.addTarget(small_spec, allocator, "mg_impl_detail",            "top/mem/impl_detail-aux.zig");
    const options: *build.Target                    = mg_aux.addTarget(small_spec, allocator, "mg_options",                "top/mem/options-aux.zig");
    const type_specs: *build.Target                 = mg_aux.addTarget(small_spec, allocator, "mg_type_specs",             "top/mem/type_specs-aux.zig");
    const type_descr: *build.Target                 = mg_aux.addTarget(small_spec, allocator, "mg_type_descr",             "top/mem/type_descr-aux.zig");
    const impl_variants: *build.Target              = mg_aux.addTarget(small_spec, allocator, "mg_impl_variants",          "top/mem/impl_variants-aux.zig");
    const canonical: *build.Target                  = mg_aux.addTarget(small_spec, allocator, "mg_canonical",              "top/mem/canonical-aux.zig");
    const canonicals: *build.Target                 = mg_aux.addTarget(small_spec, allocator, "mg_canonicals",             "top/mem/canonicals-aux.zig");
    const containers: *build.Target                 = mg_aux.addTarget(small_spec, allocator, "mg_containers",             "top/mem/containers-aux.zig");
    const kinds: *build.Target                      = mg_aux.addTarget(small_spec, allocator, "mg_kinds",                  "top/mem/kinds-aux.zig");
    const specifications: *build.Target             = mg_aux.addTarget(small_spec, allocator, "mg_specifications",         "top/mem/specifications-aux.zig");

    // const generate_functions: *build.Target         = mg.addTarget(small_spec, allocator, "generate_functions",        "top/mem/generate_functions.zig");
    const generate_specifications: *build.Target    = mg.addTarget(small_spec, allocator, "generate_specifications",   "top/mem/generate_specifications.zig");
    const generate_references: *build.Target        = mg.addTarget(small_spec, allocator, "generate_references",       "top/mem/generate_references.zig");
    const generate_parameters: *build.Target        = mg.addTarget(small_spec, allocator, "generate_parameters",       "top/mem/generate_parameters.zig");
    const generate_containers: *build.Target        = mg.addTarget(small_spec, allocator, "generate_containers",       "top/mem/generate_containers.zig");

    type_specs.dependOnRun(allocator, abstract_params);
    type_descr.dependOnRun(allocator, type_specs);
    impl_variants.dependOnRun(allocator, type_specs);
    impl_variants.dependOnRun(allocator, impl_detail);
    canonicals.dependOnRun(allocator, impl_variants);
    canonicals.dependOnRun(allocator, canonical);
    containers.dependOnRun(allocator, canonicals);
    kinds.dependOnRun(allocator, canonicals);
    // generate_functions.dependOnRun(allocator, impl_variants);
    // generate_functions.dependOnRun(allocator, expr_test);
    specifications.dependOnRun(allocator, containers);
    generate_specifications.dependOnRun(allocator, options);
    generate_specifications.dependOnRun(allocator, type_descr);
    generate_specifications.dependOnRun(allocator, specifications);
    generate_references.dependOnRun(allocator, containers);
    generate_references.dependOnRun(allocator, generate_specifications);
    generate_parameters.dependOnRun(allocator, options);
    generate_parameters.dependOnRun(allocator, type_descr);
    generate_parameters.dependOnRun(allocator, containers);
    generate_containers.dependOnRun(allocator, generate_parameters);
    }

    // zig fmt: on

    for ([_]*build.Target{
        builtin_test, meta_test,    mem_test,   algo_test,
        file_test,    list_test,    fmt_test,   render_test,
        thread_test,  virtual_test, build_test,
    }) |_| {}
    for (.{ mca, treez, itos, cat, hello, readelf, parsedir }) |_| {}
    for (.{ impl_test, container_test, parse_test, lib_parser_test, std_parser_test }) |_| {}
    for (.{ readdir, dynamic, address_space }) |_| {}
}
