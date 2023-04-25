const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const sys = @import("./sys.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const build = @import("./build2.zig");
const spec = @import("./spec.zig");
const builtin = @import("./builtin.zig");
const virtual = @import("./virtual.zig");
const testing = @import("./testing.zig");
const command_line = build.command_line;

pub usingnamespace proc.start;

pub const Builder = build.GenericBuilder(spec.builder.default);
pub const runtime_assertions: bool = false;

const PartialCommand = struct {
    kind: build.OutputMode,
    mode: builtin.Mode,

    image_base: u64 = 0x10000,
    strip: bool = true,
    static: bool = true,
    compiler_rt: bool = false,
    reference_trace: bool = true,
    single_threaded: bool = true,
    function_sections: bool = true,
    omit_frame_pointer: bool = false,

    modules: []const build.Module = &.{
        .{ .name = "zig_lib", .path = "zig_lib.zig" },
        .{ .name = "@build", .path = "build.zig" },
        .{ .name = "env", .path = "zig-cache/env.zig" },
    },
    dependencies: []const build.ModuleDependency = &.{
        .{ .name = "zig_lib" },
        .{ .name = "@build" },
        .{ .name = "env" },
    },
};

const exe_default: PartialCommand = .{ .kind = .exe, .mode = .ReleaseSmall };
const obj_default: PartialCommand = .{ .kind = .obj, .mode = .ReleaseSmall };
const exe_debug: PartialCommand = .{ .kind = .exe, .mode = .Debug };

pub fn testBuildProgram(allocator: *Builder.Allocator, builder: *Builder) !void {
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
    const build_test: *Builder.Target =         try tests.addTarget(allocator, exe_debug,   "build_test",   "build_runner2.zig");
    const build2_test: *Builder.Target =        try tests.addTarget(allocator, exe_debug,   "build2_test",  "top/build2-test.zig");
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
    const mg_impl_detail: *Builder.Target =     try mg.addTarget(allocator, obj_default,    "mg_impl_detail",       "top/mem/serial_impl_detail.zig");
    const mg_ctn_detail: *Builder.Target =      try mg.addTarget(allocator, obj_default,    "mg_ctn_detail",        "top/mem/serial_ctn_detail.zig");
    const mg_new_type_specs: *Builder.Target =  try mg.addTarget(allocator, exe_default,    "mg_new_type_specs",    "top/mem/new_type_specs-aux.zig");
    const mg_reference_impls: *Builder.Target = try mg.addTarget(allocator, exe_default,    "mg_reference_impls",   "top/mem/reference_impls-aux.zig");
    const mg_container_impls: *Builder.Target = try mg.addTarget(allocator, exe_default,    "mg_container_impls",   "top/mem/container_impls-aux.zig");
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
    build_test.descr =          "Test the special test build program";
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
    mg_impl_detail.descr =      "Serialiser for `[]const Implementation`";
    mg_ctn_detail.descr =       "Serialiser for `[]const Container`";
    mg_new_type_specs.descr =   "Generate data and container->reference deductions";
    mg_container_kinds.descr =  "Generate function kind switch functions for container functions";
    mg_allocator_kinds.descr =  "Generate function kind switch functions for allocator functions";
    mg_reference_impls.descr =  "Generate reference implementations";
    mg_container_impls.descr =  "Generate container implementations";
    generate_build.descr =      "Generate builder command line implementation";

    // Dependencies:
    mg_container_impls.dependOnRun(allocator,       mg_container_kinds);
    mg_new_type_specs.dependOnRun(allocator,        mg_touch);
    mg_new_type_specs.dependOnObject(allocator,     mg_options);
    mg_new_type_specs.dependOnObject(allocator,     mg_params);
    mg_new_type_specs.dependOnObject(allocator,     mg_techs);
    mg_new_type_specs.dependOnObject(allocator,     mg_specs);
    mg_new_type_specs.dependOnObject(allocator,     mg_ctn_detail);
    mg_new_type_specs.dependOnObject(allocator,     mg_impl_detail);
    mg_container_impls.dependOnObject(allocator,    mg_ctn_detail);
    mg_container_impls.dependOnObject(allocator,    mg_impl_detail);
    mg_reference_impls.dependOnObject(allocator,    mg_ctn_detail);
    mg_reference_impls.dependOnObject(allocator,    mg_impl_detail);

    catz.emitAuxiliary(allocator, builder, .@"asm");

    build_test.addRunArgument(allocator, builder.zig_exe);
    build_test.addRunArgument(allocator, builder.build_root);
    build_test.addRunArgument(allocator, builder.cache_root);
    build_test.addRunArgument(allocator, builder.global_cache_root);
    build2_test.addRunArgument(allocator, builder.zig_exe);
    build2_test.addRunArgument(allocator, builder.build_root);
    build2_test.addRunArgument(allocator, builder.cache_root);
    build2_test.addRunArgument(allocator, builder.global_cache_root);

    const g3 = try builder.addGroup(allocator, "g3");
    const t2: *Builder.Target = try g3.addTarget(allocator, obj_default, "obj0", "test/src/obj0.zig");
    const t3: *Builder.Target = try g3.addTarget(allocator, obj_default, "obj1", "test/src/obj1.zig");
    const t4: *Builder.Target = try g3.addTarget(allocator, obj_default, "obj2", "test/src/obj2.zig");
    const t5: *Builder.Target = try g3.addTarget(allocator, obj_default, "obj3", "test/src/obj3.zig");
    const t6: *Builder.Target = try g3.addTarget(allocator, obj_default, "obj4", "test/src/obj4.zig");
    const t7: *Builder.Target = try g3.addTarget(allocator, obj_default, "obj5", "test/src/obj5.zig");
    const t1: *Builder.Target = try g3.addTarget(allocator, obj_default, "lib0", "test/src/lib0.zig");
    const t0: *Builder.Target = try g3.addTarget(allocator, obj_default, "lib1", "test/src/lib1.zig");
    const t: *Builder.Target = try g3.addTarget(allocator, exe_default, "bin", "test/src/main.zig");
    t1.dependOnObject(allocator, t2);
    t1.dependOnObject(allocator, t3);
    t1.dependOnObject(allocator, t4);
    t0.dependOnObject(allocator, t1);
    t0.dependOnObject(allocator, t2);
    t0.dependOnObject(allocator, t3);
    t.dependOnObject(allocator, t0);
    t.dependOnObject(allocator, t5);
    t.dependOnObject(allocator, t6);
    t.dependOnObject(allocator, t7);

    // zig fmt: on
}
fn testBuildRunner(args: [][*:0]u8, vars: [][*:0]u8, comptime main_fn: anytype) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: Builder.Allocator = Builder.Allocator.init(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const cmds: [][*:0]u8 = args[5..];
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try main_fn(&allocator, &builder);
    var target_task: build.Task = .build;
    for (cmds, 0..) |arg, idx| {
        const command: []const u8 = meta.manyToSlice(arg);
        if (builder.args_len == builder.args.len) {
            if (mach.testEqualMany8(command, "build")) {
                target_task = .build;
                continue;
            } else if (mach.testEqualMany8(command, "--")) {
                builder.args_len = idx +% 6;
                continue;
            } else if (mach.testEqualMany8(command, "run")) {
                target_task = .run;
                continue;
            } else if (mach.testEqualMany8(command, "show")) {
                return Builder.debug.builderCommandNotice(&builder, true, true, true);
            }
        }
        for (builder.groups()) |group| {
            if (mach.testEqualMany8(command, group.name)) {
                try meta.wrap(group.executeToplevel(&address_space, &thread_space, &allocator, target_task));
            } else for (group.targets()) |target| {
                if (mach.testEqualMany8(command, target.name)) {
                    try meta.wrap(target.executeToplevel(&address_space, &thread_space, &allocator, &builder, target_task));
                }
            }
        }
    }
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try testBuildRunner(args, vars, @import("../build.zig").buildMain);
}
