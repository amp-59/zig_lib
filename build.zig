pub const srg = @import("./zig_lib.zig");

const proc = srg.proc;
const spec = srg.spec;
const meta = srg.meta;
const build = srg.build2;
const builtin = srg.builtin;

pub const runtime_assertions: bool = false;

pub const Builder: type = build.GenericBuilder(spec.builder.default);

pub const message_style: [:0]const u8 = "\x1b[2m";

const mods: []const build.Module = &.{
    .{ .name = "zig_lib", .path = "zig_lib.zig" },
    .{ .name = "@build", .path = "build.zig" },
    .{ .name = "env", .path = "zig-cache/env.zig" },
};
const mod_deps: []const build.ModuleDependency = &.{
    .{ .name = "zig_lib" },
    .{ .name = "@build" },
    .{ .name = "env" },
};

const PartialCommand = struct {
    kind: build.OutputMode,
    mode: builtin.Mode,

    image_base: u64 = 0x10000,
    strip: bool = true,
    static: bool = true,
    compiler_rt: bool = false,
    enable_cache: bool = true,
    reference_trace: bool = true,
    single_threaded: bool = true,
    function_sections: bool = true,
    omit_frame_pointer: bool = false,

    modules: []const build.Module = mods,
    dependencies: []const build.ModuleDependency = mod_deps,
};

const exe_default: PartialCommand = .{ .kind = .exe, .mode = .ReleaseSmall };
const obj_default: PartialCommand = .{ .kind = .obj, .mode = .ReleaseSmall };
const exe_debug: PartialCommand = .{ .kind = .exe, .mode = .Debug };
const exe_build: PartialCommand = .{ .kind = .exe, .mode = .Debug, .strip = false };

pub fn buildMain(allocator: *Builder.Allocator, builder: *Builder) !void {
    // zig fmt: off
    // Groups:
    const tests: *Builder.Group =               try builder.addGroup(allocator,             "tests");
    const builtin_test: *Builder.Target =       try tests.addTarget(allocator, exe_default, "builtin_test", "top/builtin-test.zig");
    const meta_test: *Builder.Target =          try tests.addTarget(allocator, exe_default, "meta_test",    "top/meta-test.zig");
    const mem_test: *Builder.Target =           try tests.addTarget(allocator, exe_default, "mem_test",     "top/mem-test.zig");
    const algo_test: *Builder.Target =          try tests.addTarget(allocator, exe_default, "algo_test",    "top/algo-test.zig");
    const file_test: *Builder.Target =          try tests.addTarget(allocator, exe_default, "file_test",    "top/file-test.zig");
    const list_test: *Builder.Target =          try tests.addTarget(allocator, exe_default, "list_test",    "top/list-test.zig");
    const fmt_test: *Builder.Target =           try tests.addTarget(allocator, exe_default, "fmt_test",     "top/fmt-test.zig");
    const render_test: *Builder.Target =        try tests.addTarget(allocator, exe_default, "render_test",  "top/render-test.zig");
    const build_test: *Builder.Target =         try tests.addTarget(allocator, exe_build,   "build_test",   "build_runner.zig");
    const build2_test: *Builder.Target =        try tests.addTarget(allocator, exe_build,   "build2_test",  "top/build2-test.zig");
    const serial_test: *Builder.Target =        try tests.addTarget(allocator, exe_default, "serial_test",  "top/serial-test.zig");
    const thread_test: *Builder.Target =        try tests.addTarget(allocator, exe_default, "thread_test",  "top/thread-test.zig");
    const virtual_test: *Builder.Target =       try tests.addTarget(allocator, exe_default, "virtual_test", "top/virtual-test.zig");
    const size_test: *Builder.Target =          try tests.addTarget(allocator, exe_default, "size_test",    "test/size_per_config.zig");
    const container_test: *Builder.Target =     try tests.addTarget(allocator, exe_default, "container_test", "top/container-test.zig");

    const examples: *Builder.Group =            try builder.addGroup(allocator,                 "examples");
    const readdir: *Builder.Target =            try examples.addTarget(allocator, exe_default,  "readdir",      "examples/iterate_dir_entries.zig");
    const dynamic: *Builder.Target =            try examples.addTarget(allocator, exe_default,  "dynamic",      "examples/dynamic_alloc.zig");
    const custom: *Builder.Target =             try examples.addTarget(allocator, exe_default,  "addrspace",    "examples/custom_address_space.zig");
    const allocators: *Builder.Target =         try examples.addTarget(allocator, exe_default,  "allocators",   "examples/allocators.zig");
    const mca: *Builder.Target =                try examples.addTarget(allocator, exe_default,  "mca",          "examples/mca.zig");
    const treez: *Builder.Target =              try examples.addTarget(allocator, exe_default,  "treez",        "examples/treez.zig");
    const itos: *Builder.Target =               try examples.addTarget(allocator, exe_default,  "itos",         "examples/itos.zig");
    const catz: *Builder.Target =               try examples.addTarget(allocator, exe_default,  "catz",         "examples/catz.zig");
    const cleanup: *Builder.Target =            try examples.addTarget(allocator, exe_default,  "cleanup",      "examples/cleanup.zig");
    const hello: *Builder.Target =              try examples.addTarget(allocator, exe_default,  "hello",        "examples/hello.zig");
    const readelf: *Builder.Target =            try examples.addTarget(allocator, exe_default,  "readelf",      "examples/readelf.zig");
    const pathsplit: *Builder.Target =          try examples.addTarget(allocator, exe_default,  "pathsplit",    "examples/pathsplit.zig");
    const declprint: *Builder.Target =          try examples.addTarget(allocator, exe_default,  "declprint",    "examples/declprint.zig");

    const mg: *Builder.Group =                  try builder.addGroup(allocator,             "memgen");
    const mg_touch: *Builder.Target =           try mg.addTarget(allocator, exe_default,    "mg_touch",             "top/mem/touch-aux.zig");
    const mg_specs: *Builder.Target =           try mg.addTarget(allocator, obj_default,    "mg_specs",             "top/mem/serial_specs.zig");
    const mg_techs: *Builder.Target =           try mg.addTarget(allocator, obj_default,    "mg_techs",             "top/mem/serial_techs.zig");
    const mg_params: *Builder.Target =          try mg.addTarget(allocator, obj_default,    "mg_params",            "top/mem/serial_params.zig");
    const mg_options: *Builder.Target =         try mg.addTarget(allocator, obj_default,    "mg_options",           "top/mem/serial_options.zig");
    const mg_abstract_specs: *Builder.Target =  try mg.addTarget(allocator, obj_default,    "mg_abstract_specs",    "top/mem/serial_abstract_specs.zig");
    const mg_new_type_specs: *Builder.Target =  try mg.addTarget(allocator, exe_debug,      "mg_new_type_specs",    "top/mem/new_type_specs-aux.zig");
    const mg_reference_impls: *Builder.Target = try mg.addTarget(allocator, exe_default,    "mg_reference_impls",   "top/mem/reference_impls-aux.zig");
    const mg_container_impls: *Builder.Target = try mg.addTarget(allocator, exe_debug,      "mg_container_impls",   "top/mem/container_impls-aux.zig");
    const mg_container_kinds: *Builder.Target = try mg.addTarget(allocator, exe_default,    "mg_container_kinds",   "top/mem/container_kinds-aux.zig");
    const mg_allocator_kinds: *Builder.Target = try mg.addTarget(allocator, exe_default,    "mg_allocator_kinds",   "top/mem/allocator_kinds-aux.zig");

    const bg: *Builder.Group =                  try builder.addGroup(allocator,             "buildgen");
    const generate_build: *Builder.Target =     try bg.addTarget(allocator, exe_default,    "generate_build",       "top/build/generate_build2.zig");

    // Descriptions:
    builtin_test.descr =        "Test builtin functions";
    meta_test.descr =           "Test meta functions";
    mem_test.descr =            "Test low level memory management functions and basic container/allocator usage";
    algo_test.descr =           "Test sorting and compression functions";
    file_test.descr =           "Test low level file system operation functions";
    list_test.descr =           "Test library generic linked list";
    fmt_test.descr =            "Test user formatting functions";
    render_test.descr =         "Test library value rendering functions";
    build_test.descr =          "Test the library build runner and build program";
    build2_test.descr =         "Test the special test build program";
    serial_test.descr =         "Test data serialisation functions";
    thread_test.descr =         "Test clone and thread-safe compound/tagged sets";
    virtual_test.descr =        "Test address spaces, sub address spaces, and arenas";
    size_test.descr =           "Test sizes of various things";
    container_test.descr =      "Test container implementation";
    readdir.descr =             "Shows how to iterate directory entries";
    dynamic.descr =             "Shows how to allocate dynamic memory";
    custom.descr =              "Shows a complex custom address space";
    allocators.descr =          "Shows how to use many allocators";
    mca.descr =                 "Example program useful for extracting section from assembly for machine code analysis";
    treez.descr =               "Example program useful for listing the contents of directories in a tree-like format";
    itos.descr =                "Example program useful for converting between a variety of integer formats and bases";
    catz.descr =                "Shows how to map and write a file to standard output";
    cleanup.descr =             "Shows more advanced operations on a mapped file";
    hello.descr =               "Shows various ways of printing 'Hello, world!'";
    readelf.descr =             "Example program (defunct) for parsing and displaying information about ELF binaries";
    declprint.descr =           "Useful for printing declarations";
    pathsplit.descr =           "Useful for splitting paths into dirnames and basename";

    mg_touch.descr =            "Creates placeholder files";
    mg_specs.descr =            "Serialiser for `[]const []const []const Specifier`";
    mg_techs.descr =            "Serialiser for `[]const []const []const Technique`";
    mg_params.descr =           "Serialiser for `[]const [] Specifier`";
    mg_options.descr =          "Serialiser for `[]const []const Technique`";
    mg_abstract_specs.descr =   "Serialiser for `[]const AbstractSpecification`";
    mg_new_type_specs.descr =   "Generate data and container->reference deductions";
    mg_container_kinds.descr =  "Generate function kind switch functions for container functions";
    mg_allocator_kinds.descr =  "Generate function kind switch functions for allocator functions";
    mg_reference_impls.descr =  "Generate reference implementations";
    mg_container_impls.descr =  "Generate container implementations";
    generate_build.descr =      "Generate builder command line implementation";

    // Dependencies:
    mg_new_type_specs.dependOnRun(allocator,        mg_touch);
    mg_new_type_specs.dependOnObject(allocator,     mg_options);
    mg_new_type_specs.dependOnObject(allocator,     mg_params);
    mg_new_type_specs.dependOnObject(allocator,     mg_techs);
    mg_new_type_specs.dependOnObject(allocator,     mg_specs);
    mg_container_impls.dependOnRun(allocator,       mg_new_type_specs);
    mg_container_impls.dependOnRun(allocator,       mg_container_kinds);
    mg_reference_impls.dependOnRun(allocator,       mg_new_type_specs);

    addEnvPathArgs(allocator, builder, build_test);
    addEnvPathArgs(allocator, builder, build2_test);
    addEnvPathArgs(allocator, builder, serial_test);
    // zig fmt: on
}
fn addEnvPathArgs(allocator: *Builder.Allocator, builder: *Builder, target: *Builder.Target) void {
    target.addRunArgument(allocator, builder.zig_exe);
    target.addRunArgument(allocator, builder.build_root);
    target.addRunArgument(allocator, builder.cache_root);
    target.addRunArgument(allocator, builder.global_cache_root);
}
