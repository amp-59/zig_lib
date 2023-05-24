pub const srg = @import("./zig_lib.zig");
const proc = srg.proc;
const spec = srg.spec;
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
        .{ .name = "env" },
        .{ .name = "@build" },
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
        .name = "env",
        .path = "zig-cache/env.zig",
    }, .{
        .name = "@build",
        .path = "./build.zig",
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
    const targetgen: *Builder.Group =       try builder.addGroup(allocator, "targetgen");
    // Tests
    build_cmd.mode = .Debug;
    const serial_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd,    .{ .name = "serial_test",   .root = "test/serial-test.zig" });
    const decl_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "decl_test",     .root = "test/decl-test.zig" });
    const builtin_test: *Builder.Target =   try tests.addBuild(allocator, build_cmd,    .{ .name = "builtin_test",  .root = "test/builtin-test.zig" });
    const meta_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "meta_test",     .root = "test/meta-test.zig" });
    const algo_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "algo_test",     .root = "test/algo-test.zig" });
    const math_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "math_test",     .root = "test/math-test.zig" });


    const file_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "file_test",     .root = "test/file-test.zig" });
    const list_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "list_test",     .root = "test/list-test.zig" });
    const fmt_test: *Builder.Target =       try tests.addBuild(allocator, build_cmd,    .{ .name = "fmt_test",      .root = "test/fmt-test.zig" });
    //const parse_test: *Builder.Target =     try tests.addBuild(allocator, build_cmd,    .{ .name = "parse_test",    .root = "test/parse-test.zig" });
    //const rng_test: *Builder.Target =       try tests.addBuild(allocator, build_cmd,    .{ .name = "rng_test",      .root = "test/rng-test.zig" });
    const render_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd,    .{ .name = "render_test",   .root = "test/render-test.zig" });
    const thread_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd,    .{ .name = "thread_test",   .root = "test/thread-test.zig" });
    const virtual_test: *Builder.Target =   try tests.addBuild(allocator, build_cmd,    .{ .name = "virtual_test",  .root = "test/virtual-test.zig" });
    const time_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "time_test",     .root = "test/time-test.zig" });
    const size_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "size_test",     .root = "test/size_per_config.zig" });
    // Example programs
    const readdir: *Builder.Target =        try eg.addBuild(allocator, build_cmd,       .{ .name = "readdir",   .root = "examples/dir_iterator.zig" });
    const dynamic: *Builder.Target =        try eg.addBuild(allocator, build_cmd,       .{ .name = "dynamic",   .root = "examples/dynamic_alloc.zig" });
    const custom: *Builder.Target =         try eg.addBuild(allocator, build_cmd,       .{ .name = "addrspace", .root = "examples/addrspace.zig" });
    const allocators: *Builder.Target =     try eg.addBuild(allocator, build_cmd,       .{ .name = "allocator", .root = "examples/allocator.zig" });
    const display: *Builder.Target =        try eg.addBuild(allocator, build_cmd,       .{ .name = "display",   .root = "examples/display.zig" });
    const mca: *Builder.Target =            try eg.addBuild(allocator, build_cmd,       .{ .name = "mca",       .root = "examples/mca.zig" });
    const treez: *Builder.Target =          try eg.addBuild(allocator, build_cmd,       .{ .name = "treez",     .root = "examples/treez.zig" });
    const itos: *Builder.Target =           try eg.addBuild(allocator, build_cmd,       .{ .name = "itos",      .root = "examples/itos.zig" });
    const catz: *Builder.Target =           try eg.addBuild(allocator, build_cmd,       .{ .name = "catz",      .root = "examples/catz.zig" });
    const mv: *Builder.Target =             try eg.addBuild(allocator, build_cmd,       .{ .name = "mv",        .root = "examples/mv.zig" });
    const cleanup: *Builder.Target =        try eg.addBuild(allocator, build_cmd,       .{ .name = "cleanup",   .root = "examples/cleanup.zig" });
    const hello: *Builder.Target =          try eg.addBuild(allocator, build_cmd,       .{ .name = "hello",     .root = "examples/hello.zig" });
    const readelf: *Builder.Target =        try eg.addBuild(allocator, build_cmd,       .{ .name = "readelf",   .root = "examples/readelf.zig" });
    const pathsplit: *Builder.Target =      try eg.addBuild(allocator, build_cmd,       .{ .name = "pathsplit", .root = "examples/pathsplit.zig" });
    const declprint: *Builder.Target =      try eg.addBuild(allocator, build_cmd,       .{ .name = "declprint", .root = "examples/declprint.zig" });
    //const user_project: *Builder.Target =   try eg.addBuild(allocator, build_cmd,       .{ .name = "user_project",
    //                                                                                       .root = "examples/project_with_main/build.zig" });
    //_ = user_project;
    build_cmd.gc_sections = false;
    const junk_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "junk_test", .root = "test/junk-test.zig" });
    build_cmd.gc_sections = true;
    build_cmd.strip = false;
    const builder0_test: *Builder.Target =  try tests.addBuild(allocator, build_cmd,    .{ .name = "lib_test",      .root = "build_runner.zig" });
    const builder1_test: *Builder.Target =  try tests.addBuild(allocator, build_cmd,    .{ .name = "zls_test",      .root = "zls_build_runner.zig" });
    const builder2_test: *Builder.Target =  try tests.addBuild(allocator, build_cmd,    .{ .name = "cmdline_test",  .root = "test/cmdline-test.zig" });
    build_cmd.strip = true;
    build_cmd.mode = .ReleaseSmall;
    //const crypto_test: *Builder.Target =    try tests.addBuild(allocator, build_cmd,    .{ .name = "crypto_test", .root = "test/crypto-test.zig" });
    const mem_test: *Builder.Target =       try tests.addBuild(allocator, build_cmd,    .{ .name = "mem_test",      .root = "test/mem-test.zig" });
    //const mem2_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "mem2_test",     .root = "test/mem2-test.zig" });
    const proc_test: *Builder.Target =      try tests.addBuild(allocator, build_cmd,    .{ .name = "proc_test",     .root = "test/proc-test.zig" });

    // Memory implementation generator:
    build_cmd.kind = .exe;
    build_cmd.mode = .Debug;
    const mg_touch: *Builder.Target =       try mg_aux.addBuild(allocator, build_cmd,   .{ .name = "mg_touch", .root = "top/mem/gen/touch.zig" });
    const mg_specs: *Builder.Target =       try mg_aux.addBuild(allocator, build_cmd,   .{ .name = "mg_specs", .root = "top/mem/gen/specs.zig" });
    const mg_ctn_kinds: *Builder.Target =   try mg_aux.addBuild(allocator, build_cmd,   .{ .name = "mg_ctn_kinds", .root = "top/mem/gen/ctn_kinds.zig" });
    const mg_ptr_impls: *Builder.Target =   try mg_aux.addBuild(allocator, build_cmd,   .{ .name = "mg_ptr_impls", .root = "top/mem/gen/ptr_impls.zig" });
    const mg_ctn_impls: *Builder.Target =   try mg_aux.addBuild(allocator, build_cmd,   .{ .name = "mg_ctn_impls", .root = "top/mem/gen/ctn_impls.zig" });
    const mg_ctn: *Builder.Target =         try memgen.addFormat(allocator, format_cmd, .{ .name = "mg_ctn", .root = "top/mem/ctn.zig" });
    const mg_ptr: *Builder.Target =         try memgen.addFormat(allocator, format_cmd, .{ .name = "mg_ptr", .root = "top/mem/ptr.zig" });
    // Builder implementation generator:
    build_cmd.mode = .ReleaseSmall;
    const bg_tasks_impls: *Builder.Target =   try bg_aux.addBuild(allocator, build_cmd, .{ .name = "bg_tasks_impls",
                                                                                           .root = "top/build/gen/tasks_impls.zig" });
    const bg_cmdline_impls: *Builder.Target = try bg_aux.addBuild(allocator, build_cmd, .{ .name = "bg_cmdline_impls",
                                                                                           .root = "top/build/gen/cmdline_impls.zig" });
    const bg_tasks: *Builder.Target =   try buildgen.addFormat(allocator, format_cmd,   .{ .name = "bg_tasks",      .root = "top/build/tasks.zig" });
    const bg_cmdline: *Builder.Target = try buildgen.addFormat(allocator, format_cmd,   .{ .name = "bg_cmdline",    .root = "top/build/cmdline.zig" });
    const tg_cpu_impl: *Builder.Target = try targetgen.addBuild(allocator, build_cmd,   .{ .name = "tg_feat_impls",
                                                                                           .root = "top/target/gen/feat_impls.zig" });
    tg_cpu_impl.task_cmd.build.compiler_rt = true;
    tg_cpu_impl.task_cmd.build.mode = .ReleaseSmall;
    // Descriptions:
    builtin_test.descr =    "Test builtin functions";
    meta_test.descr =       "Test meta functions";
    mem_test.descr =        "Test low level memory management functions and basic container/allocator usage";
    //mem2_test.descr =       "Test v2 low level memory implementation";
    algo_test.descr =       "Test sorting and compression functions";
    math_test.descr =       "Test math functions";
    file_test.descr =       "Test low level file system operation functions";
    list_test.descr =       "Test library generic linked list";
    //rng_test.descr =        "Test random number generation functions";
    //crypto_test.descr =     "Test crypto related functions";
    junk_test.descr =       "Test how much junk is generated by Zig exceptions";
    fmt_test.descr =        "Test user formatting functions";
    //parse_test.descr =      "Test generic parsing function";
    render_test.descr =     "Test library value rendering functions";
    proc_test.descr =       "Test process related functions";
    time_test.descr =       "Test time related functions";
    builder0_test.descr =   "Test the library build runner and build program. Used to show size and compile time";
    builder1_test.descr =   "Test the library builder command line functions";
    builder2_test.descr =   "Test the ZLS special build runner";
    decl_test.descr =       "Test compilation of all public declarations recursively";
    serial_test.descr =     "Test data serialisation functions";
    thread_test.descr =     "Test clone and thread-safe compound/tagged sets";
    virtual_test.descr =    "Test address spaces, sub address spaces, and arenas";
    size_test.descr =       "Test sizes of various things";
    readdir.descr =         "Shows how to iterate directory entries";
    dynamic.descr =         "Shows how to allocate dynamic memory";
    custom.descr =          "Shows a complex custom address space";
    allocators.descr =      "Shows how to use many allocators";
    display.descr =         "Shows using `ioctl` to get display resources (idkso)";
    mca.descr =             "Example program useful for extracting section from assembly for machine code analysis";
    treez.descr =           "Example program useful for listing the contents of directories in a tree-like format";
    //user_project.descr =    "Example project useful for simulating basic library usage";
    itos.descr =            "Example program useful for converting between a variety of integer formats and bases";
    catz.descr =            "Shows how to map and write a file to standard output";
    cleanup.descr =         "Shows more advanced operations on a mapped file";
    hello.descr =           "Shows various ways of printing 'Hello, world!'";
    readelf.descr =         "Example program (defunct) for parsing and displaying information about ELF binaries";
    declprint.descr =       "Useful for printing declarations";
    pathsplit.descr =       "Useful for splitting paths into dirnames and basename";
    mg_touch.descr =        "Create placeholder files";
    mg_specs.descr =        "Generate specification types for containers and pointers";
    mg_ctn_kinds.descr =    "Generate function kind switch functions for container functions";
    mg_ptr_impls.descr =    "Generate reference implementations";
    mg_ctn_impls.descr =    "Generate container implementations";
    mg_ptr.descr =          "Reformat generated generic pointers into canonical form";
    mg_ctn.descr =          "Reformat generated generic containers into canonical form";
    bg_tasks.descr =        "Generate builder command line data structures";
    bg_cmdline.descr =      "Generate builder command line writer functions";
    bg_tasks.descr =        "Reformat generated builder command line data structures into canonical form";
    bg_cmdline.descr =      "Reformat generated builder command line writer functions into canonical form";
    // Dependencies:
    mg_specs.dependOnRun(allocator,         mg_touch);
    mg_ptr_impls.dependOnRun(allocator,     mg_specs);
    mg_ptr.dependOnRun(allocator,           mg_ptr_impls);
    mg_ctn_impls.dependOnRun(allocator,     mg_specs);
    mg_ctn_impls.dependOnRun(allocator,     mg_ctn_kinds);
    mg_ctn.dependOnRun(allocator,           mg_ctn_impls);
    bg_tasks.dependOnRun(allocator,         bg_tasks_impls);
    bg_cmdline.dependOnRun(allocator,       bg_cmdline_impls);
    mv.task_cmd.build.mode = .Debug;
    // zig fmt: on
    for ([_]*Builder.Target{ builder0_test, builder1_test, builder2_test, serial_test }) |target| {
        target.addRunArgument(allocator, builder.zig_exe);
        target.addRunArgument(allocator, builder.build_root);
        target.addRunArgument(allocator, builder.cache_root);
        target.addRunArgument(allocator, builder.global_cache_root);
    }
}
