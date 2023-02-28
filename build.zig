const _ = struct {
    pub const build = if (false) @import("build/build-aux.zig").main else buildMain;
};
pub usingnamespace @"_";

pub const srg = @import("./zig_lib.zig");
const mem = srg.mem;
const meta = srg.meta;
const preset = srg.preset;
const build = srg.build;
const builtin = srg.builtin;

const deps: []const []const u8 = &.{"zig_lib"};
const modules: []const build.Module = &.{.{
    .name = "zig_lib",
    .path = "./zig_lib.zig",
}};
const lib_parser_macros: []const build.Macro = &.{.{
    .name = "test_subject",
    .value = .{ .string = "lib" },
}};
const std_parser_macros: []const build.Macro = &.{.{
    .name = "test_subject",
    .value = .{ .string = "std" },
}};

// zig fmt: off
const debug_spec: build.TargetSpec =    .{ .mode = .Debug,          .mods = modules, .deps = deps };
const safe_spec: build.TargetSpec =     .{ .mode = .ReleaseSafe,    .mods = modules, .deps = deps };
const small_spec: build.TargetSpec =    .{ .mode = .ReleaseSmall,   .mods = modules, .deps = deps };
const fast_spec: build.TargetSpec =     .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps };
const parser_spec_a: build.TargetSpec = .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps, .macros = lib_parser_macros };
const parser_spec_b: build.TargetSpec = .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps, .macros = std_parser_macros };
const gen_spec: build.TargetSpec =      .{ .fmt = true, .run = false, .build = false };

pub fn buildMain(allocator: *build.Allocator, builder: *build.Builder) !void {
    // Top test programs
    const builtin_test: *build.Target   = builder.addTarget(debug_spec, allocator,  "builtin_test", "top/builtin-test.zig");
    const meta_test: *build.Target      = builder.addTarget(debug_spec, allocator,  "meta_test",    "top/meta-test.zig");
    const mem_test: *build.Target       = builder.addTarget(debug_spec, allocator,  "mem_test",     "top/mem-test.zig");
    const algo_test: *build.Target      = builder.addTarget(debug_spec, allocator,  "algo_test",    "top/algo-test.zig");
    const file_test: *build.Target      = builder.addTarget(debug_spec, allocator,  "file_test",    "top/file-test.zig");
    const list_test: *build.Target      = builder.addTarget(debug_spec, allocator,  "list_test",    "top/list-test.zig");
    const fmt_test: *build.Target       = builder.addTarget(debug_spec, allocator,  "fmt_test",     "top/fmt-test.zig");
    const render_test: *build.Target    = builder.addTarget(debug_spec, allocator,  "render_test",  "top/render-test.zig");
    const thread_test: *build.Target    = builder.addTarget(debug_spec, allocator,  "thread_test",  "top/thread-test.zig");
    const virtual_test: *build.Target   = builder.addTarget(debug_spec, allocator,  "virtual_test", "top/virtual-test.zig");
    const build_test: *build.Target     = builder.addTarget(debug_spec, allocator,  "build_test",   "top/build-test.zig");
    // More complete test programs:
    const mca: *build.Target            = builder.addTarget(fast_spec,  allocator,  "mca",      "test/mca.zig");
    const treez: *build.Target          = builder.addTarget(small_spec, allocator,  "treez",    "test/treez.zig");
    const itos: *build.Target           = builder.addTarget(small_spec, allocator,  "itos",     "test/itos.zig");
    const cat: *build.Target            = builder.addTarget(small_spec, allocator,  "cat",      "test/cat.zig");
    const hello: *build.Target          = builder.addTarget(small_spec, allocator,  "hello",    "test/hello.zig");
    const readelf: *build.Target        = builder.addTarget(small_spec, allocator,  "readelf",  "test/readelf.zig");
    const parsedir: *build.Target       = builder.addTarget(small_spec, allocator,  "parsedir", "test/parsedir.zig");
    // Other test programs:
    const impl_test: *build.Target          = builder.addTarget(debug_spec, allocator,  "impl_test",      "top/impl-test.zig");
    const container_test: *build.Target     = builder.addTarget(debug_spec, allocator,  "container_test", "top/container-test.zig");
    const parse_test: *build.Target         = builder.addTarget(debug_spec, allocator,  "parse_test",     "top/parse-test.zig");
    const lib_parser_test: *build.Target    = builder.addTarget(fast_spec, allocator,   "lib_parser",     "test/parsedir.zig");
    const std_parser_test: *build.Target    = builder.addTarget(fast_spec, allocator,   "std_parser",     "test/parsedir.zig");
    // Examples:
    const readdir: *build.Target            = builder.addTarget(small_spec, allocator,  "readdir",          "examples/iterate_dir_entries.zig");
    const dynamic: *build.Target            = builder.addTarget(small_spec, allocator,  "dynamic",          "examples/dynamic_alloc.zig");
    const address_space: *build.Target      = builder.addTarget(small_spec, allocator,  "address_space",    "examples/custom_address_space.zig");
    // Build system generator:
    const bg: *build.Group                  = builder.addGroup(allocator,           "buildgen");
    const generate_build: *build.Target     = bg.addTarget(small_spec, allocator,   "generate_build", "top/build/generate_build.zig");
    // Memory implementation generator:
    const mg_aux: *build.Group              = builder.addGroup(allocator,               "memgen_auxiliary");
    const mg_abstract_params: *build.Target = mg_aux.addTarget(small_spec, allocator,   "mg_abstract_params",       "top/mem/abstract_params-aux.zig");
    const mg_impl_detail: *build.Target     = mg_aux.addTarget(small_spec, allocator,   "mg_impl_detail",           "top/mem/impl_detail-aux.zig");
    const mg_options: *build.Target         = mg_aux.addTarget(small_spec, allocator,   "mg_options",               "top/mem/options-aux.zig");
    const mg_type_specs: *build.Target      = mg_aux.addTarget(small_spec, allocator,   "mg_type_specs",            "top/mem/type_specs-aux.zig");
    const mg_type_descr: *build.Target      = mg_aux.addTarget(small_spec, allocator,   "mg_type_descr",            "top/mem/type_descr-aux.zig");
    const mg_impl_variants: *build.Target   = mg_aux.addTarget(small_spec, allocator,   "mg_impl_variants",         "top/mem/impl_variants-aux.zig");
    const mg_canonical: *build.Target       = mg_aux.addTarget(small_spec, allocator,   "mg_canonical",             "top/mem/canonical-aux.zig");
    const mg_canonicals: *build.Target      = mg_aux.addTarget(small_spec, allocator,   "mg_canonicals",            "top/mem/canonicals-aux.zig");
    const mg_containers: *build.Target      = mg_aux.addTarget(small_spec, allocator,   "mg_containers",            "top/mem/containers-aux.zig");
    const mg_kinds: *build.Target           = mg_aux.addTarget(small_spec, allocator,   "mg_kinds",                 "top/mem/kinds-aux.zig");
    const mg_specs: *build.Target           = mg_aux.addTarget(small_spec, allocator,   "mg_specs",                 "top/mem/specs-aux.zig");
    const mg_reference_specs: *build.Target = mg_aux.addTarget(small_spec, allocator,   "mg_reference_specs",       "top/mem/reference_specs-aux.zig");
    const mg_reference_impls: *build.Target = mg_aux.addTarget(small_spec, allocator,   "mg_reference_impls",       "top/mem/reference_impls-aux.zig");
    const mg_container_specs: *build.Target = mg_aux.addTarget(small_spec, allocator,   "mg_container_specs",       "top/mem/container_specs-aux.zig");
    const mg_container_impls: *build.Target = mg_aux.addTarget(small_spec, allocator,   "mg_container_impls",       "top/mem/container_impls-aux.zig");
    const mg: *build.Group                      = builder.addGroup(allocator,           "memgen");
    const generate_containers: *build.Target    = mg.addTarget(gen_spec, allocator,     "generate_containers",      "top/mem/containers.zig");
    const generate_references: *build.Target    = mg.addTarget(gen_spec, allocator,     "generate_references",      "top/mem/references.zig");

    // Auxiliary dependencies:
    mg_type_specs.dependOnRun(allocator,        mg_abstract_params);
    mg_type_descr.dependOnRun(allocator,        mg_type_specs);
    mg_impl_variants.dependOnRun(allocator,     mg_type_specs);
    mg_impl_variants.dependOnRun(allocator,     mg_impl_detail);
    mg_canonicals.dependOnRun(allocator,        mg_impl_variants);
    mg_canonicals.dependOnRun(allocator,        mg_canonical);
    mg_containers.dependOnRun(allocator,        mg_canonicals);
    mg_kinds.dependOnRun(allocator,             mg_canonicals);
    mg_specs.dependOnRun(allocator,             mg_containers);
    mg_reference_specs.dependOnRun(allocator,   mg_options);
    mg_reference_specs.dependOnRun(allocator,   mg_type_descr);
    mg_reference_specs.dependOnRun(allocator,   mg_specs);
    mg_reference_impls.dependOnRun(allocator,   mg_containers);
    mg_reference_impls.dependOnRun(allocator,   mg_reference_specs);
    mg_container_specs.dependOnRun(allocator,   mg_options);
    mg_container_specs.dependOnRun(allocator,   mg_type_descr);
    mg_container_specs.dependOnRun(allocator,   mg_containers);
    mg_container_impls.dependOnRun(allocator,   mg_container_specs);
    // Primary dependencies:
    generate_containers.dependOnRun(allocator,  mg_container_impls);
    generate_references.dependOnRun(allocator,  mg_reference_impls);

    // zig fmt: on

    for ([_]*build.Target{
        builtin_test, meta_test,    mem_test,   algo_test,
        file_test,    list_test,    fmt_test,   render_test,
        thread_test,  virtual_test, build_test,
    }) |_| {}
    for (.{ mca, treez, itos, cat, hello, readelf, parsedir }) |_| {}
    for (.{ impl_test, container_test, parse_test, lib_parser_test, std_parser_test }) |_| {}
    for (.{ readdir, dynamic, address_space }) |_| {}
    for (.{generate_build}) |_| {}
}
