pub usingnamespace struct {
    pub const build = if (true) @import("build/build-aux.zig").main else buildMain;
};

pub const srg = @import("./zig_lib.zig");
const mem = srg.mem;
const meta = srg.meta;
const build = srg.build;
const preset = srg.preset;
const builtin = srg.builtin;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;
pub const runtime_assertions: bool = false;
pub const max_relevant_depth: u64 = if (builtin.testEqual(builtin.Logging.Override, logging_override, preset.logging.override.verbose)) 255 else 1;

const deps: []const build.ModuleDependency = &.{ .{ .name = "zig_lib" }, .{ .name = "@build" } };
const modules: []const build.Module = &.{ .{ .name = "zig_lib", .path = "./zig_lib.zig" }, .{ .name = "@build", .path = "./build.zig" } };
const lib_parser_macros: []const build.Macro = &.{.{ .name = "test_subject", .value = .{ .string = "lib" } }};
const std_parser_macros: []const build.Macro = &.{.{ .name = "test_subject", .value = .{ .string = "std" } }};

// zig fmt: off
const debug_spec: build.TargetSpec =    .{ .mode = .Debug,          .mods = modules, .deps = deps };
const safe_spec: build.TargetSpec =     .{ .mode = .ReleaseSafe,    .mods = modules, .deps = deps };
const small_spec: build.TargetSpec =    .{ .mode = .ReleaseSmall,   .mods = modules, .deps = deps };
const fast_spec: build.TargetSpec =     .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps };
const parser_spec_a: build.TargetSpec = .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps, .macros = lib_parser_macros };
const parser_spec_b: build.TargetSpec = .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps, .macros = std_parser_macros };
const build_spec: build.TargetSpec =    .{ .mode = .Debug,          .mods = modules, .deps = deps };
const gen_spec: build.TargetSpec =      .{ .fmt = true, .run = false, .build = false };

pub fn buildMain(allocator: *build.Allocator, builder: *build.Builder) !void {
    const examples: *build.Group            = builder.addGroup(allocator,               "examples");
    const readdir: *build.Target            = examples.addTarget(small_spec, allocator, "readdir",              "examples/iterate_dir_entries.zig");
    const dynamic: *build.Target            = examples.addTarget(small_spec, allocator, "dynamic",              "examples/dynamic_alloc.zig");
    const address_space: *build.Target      = examples.addTarget(small_spec, allocator, "addrspace",            "examples/custom_address_space.zig");
    const mca: *build.Target                = examples.addTarget(fast_spec,  allocator, "mca",                  "examples/mca.zig");
    const treez: *build.Target              = examples.addTarget(small_spec, allocator, "treez",                "examples/treez.zig");
    const itos: *build.Target               = examples.addTarget(small_spec, allocator, "itos",                 "examples/itos.zig");
    const catz: *build.Target               = examples.addTarget(small_spec, allocator, "catz",                 "examples/catz.zig");
    const hello: *build.Target              = examples.addTarget(small_spec, allocator, "hello",                "examples/hello.zig");
    const readelf: *build.Target            = examples.addTarget(small_spec, allocator, "readelf",              "examples/readelf.zig");
    const pathsplit: *build.Target          = examples.addTarget(small_spec, allocator, "pathsplit",            "examples/pathsplit.zig");
    const declprint: *build.Target          = examples.addTarget(debug_spec, allocator, "declprint",            "examples/declprint.zig");
    const tests: *build.Group               = builder.addGroup(allocator,               "tests");
    const build_test: *build.Target         = tests.addTarget(build_spec, allocator,    "build_test",           "build_runner.zig");
    const builtin_test: *build.Target       = tests.addTarget(debug_spec, allocator,    "builtin_test",         "top/builtin-test.zig");
    const meta_test: *build.Target          = tests.addTarget(debug_spec, allocator,    "meta_test",            "top/meta-test.zig");
    const mem_test: *build.Target           = tests.addTarget(debug_spec, allocator,    "mem_test",             "top/mem-test.zig");
    const algo_test: *build.Target          = tests.addTarget(fast_spec,  allocator,    "algo_test",            "top/algo-test.zig");
    const file_test: *build.Target          = tests.addTarget(debug_spec, allocator,    "file_test",            "top/file-test.zig");
    const list_test: *build.Target          = tests.addTarget(fast_spec,  allocator,    "list_test",            "top/list-test.zig");
    const fmt_test: *build.Target           = tests.addTarget(debug_spec, allocator,    "fmt_test",             "top/fmt-test.zig");
    const render_test: *build.Target        = tests.addTarget(small_spec, allocator,    "render_test",          "top/render-test.zig");
    const serial_test: *build.Target        = tests.addTarget(small_spec, allocator,    "serial_test",          "top/serial-test.zig");
    const thread_test: *build.Target        = tests.addTarget(debug_spec, allocator,    "thread_test",          "top/thread-test.zig");
    const virtual_test: *build.Target       = tests.addTarget(small_spec, allocator,    "virtual_test",         "top/virtual-test.zig");
    const impl_test: *build.Target          = tests.addTarget(debug_spec, allocator,    "impl_test",            "top/impl-test.zig");
    const container_test: *build.Target     = tests.addTarget(debug_spec, allocator,    "container_test",       "top/container-test.zig");
    const bg: *build.Group                  = builder.addGroup(allocator,               "buildgen");
    const generate_build: *build.Target     = bg.addTarget(small_spec, allocator,       "generate_build",       "top/build/generate_build.zig");
    const mg_aux: *build.Group              = builder.addGroup(allocator,               "memgen_auxiliary");
    const mg_touch: *build.Target           = mg_aux.addTarget(small_spec, allocator,   "mg_touch",             "top/mem/touch-aux.zig");
    const mg_new_type_specs: *build.Target  = mg_aux.addTarget(small_spec, allocator,   "mg_new_type_specs",    "top/mem/new_type_specs-aux.zig");
    const mg_new_specs: *build.Target       = mg_aux.addTarget(small_spec, allocator,   "mg_new_specs",         "top/mem/new_specs-aux.zig");
    const mg_reference_impls: *build.Target = mg_aux.addTarget(debug_spec, allocator,   "mg_reference_impls",   "top/mem/reference_impls-aux.zig");
    const mg_container_impls: *build.Target = mg_aux.addTarget(debug_spec, allocator,   "mg_container_impls",   "top/mem/container_impls-aux.zig");
    const mg_container_kinds: *build.Target = mg_aux.addTarget(debug_spec, allocator,   "mg_container_kinds",   "top/mem/container_kinds-aux.zig");
    const mg: *build.Group                      = builder.addGroup(allocator,           "memgen");
    const generate_references: *build.Target    = mg.addTarget(gen_spec, allocator,     "generate_references",  "top/mem/references.zig");
    const generate_containers: *build.Target    = mg.addTarget(gen_spec, allocator,     "generate_containers",  "top/mem/containers.zig");

    const memgen_test: *build.Target            = mg.addTarget(debug_spec, allocator,   "memgen_test",          "top/mem/memgen-test.zig");
    build_test.dependOnRun(allocator,           generate_build);
    mg_new_type_specs.dependOnRun(allocator,    mg_touch);
    mg_reference_impls.dependOnRun(allocator,   mg_touch);
    mg_container_kinds.dependOnRun(allocator,   mg_touch);
    mg_new_specs.dependOnRun(allocator,         mg_new_type_specs);
    mg_container_impls.dependOnRun(allocator,   mg_new_type_specs);
    mg_container_impls.dependOnRun(allocator,   mg_container_kinds);
    mg_reference_impls.dependOnRun(allocator,   mg_new_type_specs);
    generate_containers.dependOnRun(allocator,  mg_reference_impls);
    generate_references.dependOnRun(allocator,  mg_reference_impls);
    memgen_test.dependOnRun(allocator,          mg_new_type_specs);

    generate_references.fmt_cmd.ast_check = false;
    generate_containers.fmt_cmd.ast_check = false;

    build_test.run_cmd.addRunArgument(builder.zigExePath());
    build_test.run_cmd.addRunArgument(builder.buildRootPath());
    build_test.run_cmd.addRunArgument(builder.cacheDirPath());
    build_test.run_cmd.addRunArgument(builder.globalCacheDirPath());

    _ = readdir;
    _ = dynamic;
    _ = mca;
    _ = catz;
    _ = treez;
    _ = itos;
    _ = hello;
    _ = readelf;
    _ = pathsplit;
    _ = declprint;
    _ = builtin_test;
    _ = meta_test;
    _ = mem_test;
    _ = algo_test;
    _ = file_test;
    _ = list_test;
    _ = serial_test;
    _ = fmt_test;
    _ = render_test;
    _ = thread_test;
    _ = virtual_test;
    _ = impl_test;
    _ = container_test;
    _ = address_space;
}
