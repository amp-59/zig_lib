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
pub const max_relevant_depth: u64 = 255;

const deps: []const build.ModuleDependency = &.{
    .{ .name = "zig_lib" },
    .{ .name = "@build" },
    .{ .name = "env" },
};
const modules: []const build.Module = &.{
    .{ .name = "zig_lib", .path = "./zig_lib.zig" },
    .{ .name = "@build", .path = "./build.zig" },
    .{ .name = "env", .path = "./zig-cache/env.zig" },
};

// zig fmt: off
const debug_spec: build.TargetSpec =    .{ .mode = .Debug,          .mods = modules, .deps = deps };
const safe_spec: build.TargetSpec =     .{ .mode = .ReleaseSafe,    .mods = modules, .deps = deps };
const small_spec: build.TargetSpec =    .{ .mode = .ReleaseSmall,   .mods = modules, .deps = deps };
const fast_spec: build.TargetSpec =     .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps };
const build_spec: build.TargetSpec =    .{ .mode = .Debug,          .mods = modules, .deps = deps };
const obj_spec: build.TargetSpec =      .{ .mode = .ReleaseSmall,   .mods = modules, .deps = deps,  .build = .obj,  .fmt = false, .run = false };
const gen_spec: build.TargetSpec =      .{                          .mods = modules, .deps = deps,  .build = null,  .fmt = true,  .run = false };
const asm_spec: build.TargetSpec =      .{ .mode = .ReleaseFast,    .mods = modules, .deps = deps,  .build = null,  .run = false };

pub fn buildMain(allocator: *build.Allocator, builder: *build.Builder) !void {
    const examples: *build.Group            = builder.addGroup(allocator,               "examples");
    const readdir: *build.Target            = examples.addTarget(small_spec, allocator, "readdir",              "examples/iterate_dir_entries.zig");
    const dynamic: *build.Target            = examples.addTarget(small_spec, allocator, "dynamic",              "examples/dynamic_alloc.zig");
    const address_space: *build.Target      = examples.addTarget(small_spec, allocator, "addrspace",            "examples/custom_address_space.zig");
    const allocators: *build.Target         = examples.addTarget(small_spec, allocator, "allocators",           "examples/allocators.zig");
    const mca: *build.Target                = examples.addTarget(fast_spec,  allocator, "mca",                  "examples/mca.zig");
    const treez: *build.Target              = examples.addTarget(small_spec, allocator, "treez",                "examples/treez.zig");
    const itos: *build.Target               = examples.addTarget(small_spec, allocator, "itos",                 "examples/itos.zig");
    const catz: *build.Target               = examples.addTarget(small_spec, allocator, "catz",                 "examples/catz.zig");
    const hello: *build.Target              = examples.addTarget(small_spec, allocator, "hello",                "examples/hello.zig");
    const readelf: *build.Target            = examples.addTarget(small_spec, allocator, "readelf",              "examples/readelf.zig");
    const pathsplit: *build.Target          = examples.addTarget(small_spec, allocator, "pathsplit",            "examples/pathsplit.zig");
    const declprint: *build.Target          = examples.addTarget(debug_spec, allocator, "declprint",            "examples/declprint.zig");
    const tests: *build.Group               = builder.addGroup(allocator,               "tests");
    const build_test: *build.Target         = tests.addTarget(build_spec,   allocator,  "build_test",           "build_runner.zig");
    const builtin_test: *build.Target       = tests.addTarget(debug_spec,   allocator,  "builtin_test",         "top/builtin-test.zig");
    const meta_test: *build.Target          = tests.addTarget(debug_spec,   allocator,  "meta_test",            "top/meta-test.zig");
    const mem_test: *build.Target           = tests.addTarget(debug_spec,   allocator,  "mem_test",             "top/mem-test.zig");
    const algo_test: *build.Target          = tests.addTarget(fast_spec,    allocator,  "algo_test",            "top/algo-test.zig");
    const file_test: *build.Target          = tests.addTarget(debug_spec,   allocator,  "file_test",            "top/file-test.zig");
    const list_test: *build.Target          = tests.addTarget(fast_spec,    allocator,  "list_test",            "top/list-test.zig");
    const fmt_test: *build.Target           = tests.addTarget(debug_spec,   allocator,  "fmt_test",             "top/fmt-test.zig");
    const render_test: *build.Target        = tests.addTarget(small_spec,   allocator,  "render_test",          "top/render-test.zig");
    const serial_test: *build.Target        = tests.addTarget(small_spec,   allocator,  "serial_test",          "top/serial-test.zig");
    const thread_test: *build.Target        = tests.addTarget(debug_spec,   allocator,  "thread_test",          "top/thread-test.zig");
    const virtual_test: *build.Target       = tests.addTarget(small_spec,   allocator,  "virtual_test",         "top/virtual-test.zig");
    const impl_test: *build.Target          = tests.addTarget(debug_spec,   allocator,  "impl_test",            "top/impl-test.zig");
    const size_test: *build.Target          = tests.addTarget(debug_spec,   allocator,  "size_test",            "test/size_per_config.zig");
    const container_test: *build.Target     = tests.addTarget(debug_spec,   allocator,  "container_test",       "top/container-test.zig");
    const zig_program: *build.Target        = builder.addTarget(debug_spec, allocator,  "zig_program",          "test/zig_program.zig");
    const c_program: *build.Target          = builder.addTarget(obj_spec,   allocator,  "c_program",            "test/c_program.c");
    const bg: *build.Group                  = builder.addGroup(allocator,               "buildgen");
    const generate_build: *build.Target     = bg.addTarget(small_spec,      allocator,  "generate_build",       "top/build/generate_build.zig");
    const mg_aux: *build.Group              = builder.addGroup(allocator,               "memgen_auxiliary");
    const mg_touch: *build.Target           = mg_aux.addTarget(small_spec,  allocator,  "mg_touch",             "top/mem/touch-aux.zig");
    const mg_specs: *build.Target           = mg_aux.addTarget(obj_spec,    allocator,  "mg_specs",             "top/mem/serial_specs.zig");
    const mg_techs: *build.Target           = mg_aux.addTarget(obj_spec,    allocator,  "mg_techs",             "top/mem/serial_techs.zig");
    const mg_params: *build.Target          = mg_aux.addTarget(obj_spec,    allocator,  "mg_params",            "top/mem/serial_params.zig");
    const mg_options: *build.Target         = mg_aux.addTarget(obj_spec,    allocator,  "mg_options",           "top/mem/serial_options.zig");
    const mg_abstract_specs: *build.Target  = mg_aux.addTarget(obj_spec,    allocator,  "mg_abstract_specs",    "top/mem/serial_abstract_specs.zig");
    const mg_impl_detail: *build.Target     = mg_aux.addTarget(obj_spec,    allocator,  "mg_impl_detail",       "top/mem/serial_impl_detail.zig");
    const mg_ctn_detail: *build.Target      = mg_aux.addTarget(obj_spec,    allocator,  "mg_ctn_detail",        "top/mem/serial_ctn_detail.zig");
    const mg_new_type_specs: *build.Target      = mg_aux.addTarget(debug_spec, allocator,   "mg_new_type_specs",    "top/mem/new_type_specs-aux.zig");
    const mg_reference_impls: *build.Target     = mg_aux.addTarget(small_spec, allocator,   "mg_reference_impls",   "top/mem/reference_impls-aux.zig");
    const mg_container_impls: *build.Target     = mg_aux.addTarget(small_spec, allocator,   "mg_container_impls",   "top/mem/container_impls-aux.zig");
    const mg_container_kinds: *build.Target     = mg_aux.addTarget(debug_spec, allocator,   "mg_container_kinds",   "top/mem/container_kinds-aux.zig");
    const mg: *build.Group                      = builder.addGroup(allocator,               "memgen");
    const generate_references: *build.Target    = mg.addTarget(gen_spec, allocator,         "generate_references",  "top/mem/reference.zig");
    const generate_containers: *build.Target    = mg.addTarget(gen_spec, allocator,         "generate_containers",  "top/mem/container.zig");
    //const threaded_builder_test: *build.Target  = tests.addTarget(build_spec, allocator,    "threaded_build_test",  "top/threaded_builder-test.zig");

    zig_program.dependOnObject(allocator,       c_program);
    build_test.dependOnRun(allocator,           generate_build);
    mg_new_type_specs.dependOnRun(allocator,    mg_touch);
    mg_new_type_specs.dependOnObject(allocator, mg_specs);
    mg_new_type_specs.dependOnObject(allocator, mg_techs);
    mg_new_type_specs.dependOnObject(allocator, mg_params);
    mg_new_type_specs.dependOnObject(allocator, mg_options);
    mg_new_type_specs.dependOnObject(allocator, mg_impl_detail);
    mg_new_type_specs.dependOnObject(allocator, mg_ctn_detail);
    mg_reference_impls.dependOnRun(allocator,   mg_new_type_specs);
    mg_reference_impls.addFile(allocator,       mg_impl_detail.binPath());
    mg_container_kinds.dependOnRun(allocator,   mg_touch);
    mg_container_impls.dependOnRun(allocator,   mg_new_type_specs);
    mg_container_impls.dependOnRun(allocator,   mg_container_kinds);
    mg_container_impls.addFile(allocator,       mg_ctn_detail.binPath());
    generate_containers.dependOnRun(allocator,  mg_container_impls);
    generate_references.dependOnRun(allocator,  mg_reference_impls);
    build_test.run_cmd.addRunArgument(builder.paths.zig_exe);
    build_test.run_cmd.addRunArgument(builder.paths.build_root);
    build_test.run_cmd.addRunArgument(builder.paths.cache_dir);
    build_test.run_cmd.addRunArgument(builder.paths.global_cache_dir);

    c_program.build_cmd.link_libc = true;
    c_program.build_cmd.function_sections = true;

    zig_program.build_cmd.link_libc = true;
    zig_program.build_cmd.static = false;
    zig_program.build_cmd.mode = .ReleaseSmall;

    c_program.build_cmd.macros = &.{};
    zig_program.build_cmd.macros = &.{};

    generate_references.fmt_cmd.ast_check = false;
    generate_containers.fmt_cmd.ast_check = false;

    // zig fmt: on
    _ = .{
        readdir,   mg_abstract_specs,
        dynamic,   address_space,
        treez,     allocators,
        itos,      thread_test,
        readelf,   pathsplit,
        declprint, builtin_test,
        meta_test, mem_test,
        file_test, container_test,
        list_test, serial_test,
        mca,       fmt_test,
        catz,      virtual_test,
        impl_test, size_test,
        algo_test, render_test,
        hello,
    };
}
