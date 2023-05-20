pub const srg = @import("./zig_lib.zig");
const proc = srg.proc;
const spec = srg.spec;
const meta = srg.meta;
const build = srg.build;
const builtin = srg.builtin;
pub const runtime_assertions: bool = false;
pub const Builder: type = build.GenericBuilder(spec.builder.default);
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const message_style: [:0]const u8 = "\x1b[2m";
var build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .mode = .ReleaseSmall,
    .dependencies = &.{
        .{ .name = "zig_lib" },
        .{ .name = "@build" },
        .{ .name = "env" },
    },
    .image_base = 0x10000,
    .strip = true,
    .static = true,
    .compiler_rt = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .gc_sections = true,
    .omit_frame_pointer = false,
    .modules = &.{ .{
        .name = "zig_lib",
        .path = "zig_lib.zig",
    }, .{
        .name = "@build",
        .path = "build.zig",
    }, .{
        .name = "env",
        .path = "zig-cache/env.zig",
    } },
};
const format_cmd: build.FormatCommand = .{
    .ast_check = true,
};
pub fn buildMain(allocator: *Builder.Allocator, builder: *Builder) !void {
    // zig fmt: off
    // Groups:
    const tests: *Builder.Group =           try builder.addGroup(allocator, "tests");
    const eg: *Builder.Group =              try builder.addGroup(allocator, "examples");
    const memgen: *Builder.Group =          try builder.addGroup(allocator, "memgen");
    const mg_aux: *Builder.Group =          try builder.addGroup(allocator, "_memgen");
    const buildgen: *Builder.Group =        try builder.addGroup(allocator, "buildgen");
    const bg_aux: *Builder.Group =          try builder.addGroup(allocator, "_buildgen");
    // Tests
    const serial_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd, "serial_test",    "test/serial-test.zig");
    const decl_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "decl_test",      "test/decl-test.zig");
    const builtin_test: *Builder.Target =   try tests.addBuild(allocator, build_cmd, "builtin_test",   "test/builtin-test.zig");
    const meta_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "meta_test",      "test/meta-test.zig");
    const algo_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "algo_test",      "test/algo-test.zig");
    const math_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "math_test",      "test/math-test.zig");
    const file_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "file_test",      "test/file-test.zig");
    const list_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "list_test",      "test/list-test.zig");
    const fmt_test: *Builder.Target =       try tests.addBuild(allocator, build_cmd, "fmt_test",       "test/fmt-test.zig");
    //const rng_test: *Builder.Target =       try tests.addBuild(allocator, build_cmd, "rng_test",       "test/rng-test.zig");
    const render_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd, "render_test",    "test/render-test.zig");
    const thread_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd, "thread_test",    "test/thread-test.zig");
    const virtual_test: *Builder.Target =   try tests.addBuild(allocator, build_cmd, "virtual_test",   "test/virtual-test.zig");
    const time_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "time_test",      "test/time-test.zig");
    const size_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd, "size_test",      "test/size_per_config.zig");
    const container_test: *Builder.Target = try tests.addBuild(allocator, build_cmd, "container_test", "test/container-test.zig");
    // Example programs
    const readdir: *Builder.Target =        try eg.addBuild(allocator, build_cmd,  "readdir",      "examples/dir_iterator.zig");
    const dynamic: *Builder.Target =        try eg.addBuild(allocator, build_cmd,  "dynamic",      "examples/dynamic_alloc.zig");
    const custom: *Builder.Target =         try eg.addBuild(allocator, build_cmd,  "addrspace",    "examples/addrspace.zig");
    const allocators: *Builder.Target =     try eg.addBuild(allocator, build_cmd,  "allocators",   "examples/allocators.zig");
    const display: *Builder.Target =        try eg.addBuild(allocator, build_cmd,  "display",      "examples/display.zig");
    const mca: *Builder.Target =            try eg.addBuild(allocator, build_cmd,  "mca",          "examples/mca.zig");
    const treez: *Builder.Target =          try eg.addBuild(allocator, build_cmd,  "treez",        "examples/treez.zig");
    const itos: *Builder.Target =           try eg.addBuild(allocator, build_cmd,  "itos",         "examples/itos.zig");
    const catz: *Builder.Target =           try eg.addBuild(allocator, build_cmd,  "catz",         "examples/catz.zig");
    const cleanup: *Builder.Target =        try eg.addBuild(allocator, build_cmd,  "cleanup",      "examples/cleanup.zig");
    const hello: *Builder.Target =          try eg.addBuild(allocator, build_cmd,  "hello",        "examples/hello.zig");
    const readelf: *Builder.Target =        try eg.addBuild(allocator, build_cmd,  "readelf",      "examples/readelf.zig");
    const pathsplit: *Builder.Target =      try eg.addBuild(allocator, build_cmd,  "pathsplit",    "examples/pathsplit.zig");
    const declprint: *Builder.Target =      try eg.addBuild(allocator, build_cmd,  "declprint",    "examples/declprint.zig");
    build_cmd.gc_sections = false;
    const junk_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    "junk_test",  "test/junk-test.zig");
    build_cmd.gc_sections = true;
    build_cmd.mode = .Debug;
    //const crypto_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd,    "crypto_test",              "test/crypto-test.zig");
    build_cmd.strip = false;
    const build0_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd,    "build_runner_test",        "build_runner.zig");
    const build_zls_test: *Builder.Target = try tests.addBuild(allocator, build_cmd,    "zls_build_runner_test",    "zls_build_runner.zig");
    const build1_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd,    "cmdline_test",             "test/cmdline-test.zig");
    build_cmd.strip = true;
    build_cmd.mode = .ReleaseFast;
    const mem_test: *Builder.Target =       try tests.addBuild(allocator, build_cmd,    "mem_test",     "test/mem-test.zig");
    build_cmd.mode = .ReleaseFast;
    const mem2_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    "mem2_test",    "test/mem2-test.zig");
    const proc_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    "proc_test",    "test/proc-test.zig");
    // Memory implementation generator:
    build_cmd.kind = .obj;
    build_cmd.mode = .ReleaseSmall;
    const mg_specs: *Builder.Target =           try mg_aux.addBuild(allocator, build_cmd,   "mg_specs",             "top/mem/serial_specs.zig");
    const mg_techs: *Builder.Target =           try mg_aux.addBuild(allocator, build_cmd,   "mg_techs",             "top/mem/serial_techs.zig");
    const mg_params: *Builder.Target =          try mg_aux.addBuild(allocator, build_cmd,   "mg_params",            "top/mem/serial_params.zig");
    const mg_options: *Builder.Target =         try mg_aux.addBuild(allocator, build_cmd,   "mg_options",           "top/mem/serial_options.zig");
    const mg_abstract_specs: *Builder.Target =  try mg_aux.addBuild(allocator, build_cmd,   "mg_abstract_specs",    "top/mem/serial_abstract_specs.zig");
    build_cmd.gc_sections = true;
    build_cmd.kind = .exe;
    const mg_touch: *Builder.Target =               try mg_aux.addBuild(allocator, build_cmd,   "mg_touch",             "top/mem/touch-aux.zig");
    const mg_type_specs: *Builder.Target =          try mg_aux.addBuild(allocator, build_cmd,   "mg_type_specs",        "top/mem/type_specs-aux.zig");
    const mg_reference_impls: *Builder.Target =     try mg_aux.addBuild(allocator, build_cmd,   "mg_reference_impls",   "top/mem/reference_impls-aux.zig");
    const mg_container_impls: *Builder.Target =     try mg_aux.addBuild(allocator, build_cmd,   "mg_container_impls",   "top/mem/container_impls-aux.zig");
    const mg_container_kinds: *Builder.Target =     try mg_aux.addBuild(allocator, build_cmd,   "mg_container_kinds",   "top/mem/container_kinds-aux.zig");
    const mg_allocator_kinds: *Builder.Target =     try mg_aux.addBuild(allocator, build_cmd,   "mg_allocator_kinds",   "top/mem/allocator_kinds-aux.zig");
    const generate_containers: *Builder.Target =    try memgen.addFormat(allocator, format_cmd,    "generate_containers",  "top/mem/container.zig");
    const generate_references: *Builder.Target =    try memgen.addFormat(allocator, format_cmd,    "generate_references",  "top/mem/reference.zig");
    // Builder implementation generator:
    const bg_tasks: *Builder.Target =           try bg_aux.addBuild(allocator, build_cmd,   "bg_tasks",         "top/build/gen/tasks-aux.zig");
    const bg_cmdline: *Builder.Target =         try bg_aux.addBuild(allocator, build_cmd,   "bg_cmdline",       "top/build/gen/cmdline-aux.zig");
    const generate_cmdline: *Builder.Target =   try buildgen.addFormat(allocator, format_cmd,  "generate_cmdline", "top/build/cmdline3.zig");
    const generate_tasks: *Builder.Target =     try buildgen.addFormat(allocator, format_cmd,  "generate_tasks",   "top/build/tasks3.zig");
    // Descriptions:
    builtin_test.descr =        "Test builtin functions";
    meta_test.descr =           "Test meta functions";
    mem_test.descr =            "Test low level memory management functions and basic container/allocator usage";
    mem2_test.descr =           "Test v2 low level memory implementation";
    algo_test.descr =           "Test sorting and compression functions";
    math_test.descr =           "Test math functions";
    file_test.descr =           "Test low level file system operation functions";
    list_test.descr =           "Test library generic linked list";
    //rng_test.descr =            "Test random number generation functions";
    //crypto_test.descr =         "Test crypto related functions";
    junk_test.descr =           "Test how much junk is generated by Zig exceptions";
    fmt_test.descr =            "Test user formatting functions";
    render_test.descr =         "Test library value rendering functions";
    proc_test.descr =           "Test process related functions";
    time_test.descr =           "Test time related functions";
    build0_test.descr =         "Test the library build runner and build program. Used to show size and compile time";
    build1_test.descr =         "Test the library builder command line functions";
    build_zls_test.descr =      "Test the ZLS special build runner";
    decl_test.descr =           "Test compilation of all public declarations recursively";
    serial_test.descr =         "Test data serialisation functions";
    thread_test.descr =         "Test clone and thread-safe compound/tagged sets";
    virtual_test.descr =        "Test address spaces, sub address spaces, and arenas";
    size_test.descr =           "Test sizes of various things";
    container_test.descr =      "Test container implementation";
    readdir.descr =             "Shows how to iterate directory entries";
    dynamic.descr =             "Shows how to allocate dynamic memory";
    custom.descr =              "Shows a complex custom address space";
    allocators.descr =          "Shows how to use many allocators";
    display.descr =             "Shows using `ioctl` to get display resources (idkso)";
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
    mg_type_specs.descr =       "Generate data and container->reference deductions";
    mg_container_kinds.descr =  "Generate function kind switch functions for container functions";
    mg_allocator_kinds.descr =  "Generate function kind switch functions for allocator functions";
    mg_reference_impls.descr =  "Generate reference implementations";
    mg_container_impls.descr =  "Generate container implementations";
    bg_tasks.descr =            "Generate builder command line data structures";
    bg_cmdline.descr =          "Generate builder command line writer functions";
    generate_tasks.descr =      "Reformat generated builder command line data structures into canonical form";
    generate_cmdline.descr =    "Reformat generated builder command line writer functions into canonical form";
    // Dependencies:
    mg_type_specs.dependOnRun(allocator,        mg_touch);
    mg_type_specs.dependOnObject(allocator,     mg_techs);
    mg_type_specs.dependOnObject(allocator,     mg_specs);
    mg_reference_impls.dependOnRun(allocator,   mg_type_specs);
    generate_references.dependOnRun(allocator,  mg_reference_impls);
    mg_container_impls.dependOnRun(allocator,   mg_type_specs);
    mg_container_impls.dependOnRun(allocator,   mg_container_kinds);
    generate_containers.dependOnRun(allocator,  mg_container_impls);
    generate_tasks.dependOnRun(allocator,       bg_tasks);
    generate_cmdline.dependOnRun(allocator,     bg_cmdline);
    // Default args:
    addEnvPathArgs(allocator, builder, build0_test);
    addEnvPathArgs(allocator, builder, build1_test);
    addEnvPathArgs(allocator, builder, serial_test);
    addEnvPathArgs(allocator, builder, build_zls_test);
    // zig fmt: on
}
fn addEnvPathArgs(allocator: *Builder.Allocator, builder: *Builder, target: *Builder.Target) void {
    target.addRunArgument(allocator, builder.zig_exe);
    target.addRunArgument(allocator, builder.build_root);
    target.addRunArgument(allocator, builder.cache_root);
    target.addRunArgument(allocator, builder.global_cache_root);
}
