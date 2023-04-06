const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const build = @import("./build2.zig");
const types = build.types;
const spec = @import("./spec.zig");
const builtin = @import("./builtin.zig");
const command_line = build.command_line;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = false;

const Builder = build.GenericBuilder(.{
    .errors = spec.builder.errors.noexcept,
    .logging = spec.builder.logging.silent,
});

const mods = &.{
    .{ .name = "zig_lib", .path = "zig_lib.zig" },
    .{ .name = "@build", .path = "build.zig" },
    .{ .name = "env", .path = "zig-cache/env.zig" },
};
const deps = &.{
    .{ .name = "zig_lib" },
    .{ .name = "@build" },
    .{ .name = "env" },
};

fn define_default(cmd: anytype) @TypeOf(cmd) {
    cmd.code_model = .default;
    cmd.image_base = 0x10000;
    cmd.strip = true;
    cmd.static = true;
    cmd.mode = .ReleaseFast;
    cmd.compiler_rt = false;
    cmd.enable_cache = true;
    cmd.reference_trace = true;
    cmd.single_threaded = true;
    cmd.function_sections = true;
    cmd.omit_frame_pointer = false;
    cmd.modules = mods;
    cmd.dependencies = deps;
    return cmd;
}
fn define_obj(cmd: anytype) @TypeOf(cmd) {
    cmd.kind = .obj;
    return cmd;
}
fn define_exe(cmd: anytype) @TypeOf(cmd) {
    cmd.kind = .exe;
    return cmd;
}
const descr = struct {
    const builtin_test: [:0]const u8 = "Test builtin functions";
    const meta_test: [:0]const u8 = "Test meta functions";
    const mem_test: [:0]const u8 = "Test low level memory management functions and basic container/allocator usage";
    const algo_test: [:0]const u8 = "Test sorting and compression functions";
    const file_test: [:0]const u8 = "Test low level file system operation functions";
    const list_test: [:0]const u8 = "Test library generic linked list";
    const fmt_test: [:0]const u8 = "Test user formatting functions";
    const render_test: [:0]const u8 = "Test library value rendering functions";
    const serial_test: [:0]const u8 = "Test data serialisation functions";
    const thread_test: [:0]const u8 = "Test clone and thread-safe compound/tagged sets";
    const virtual_test: [:0]const u8 = "Test address spaces, sub address spaces, and arenas";
    const size_test: [:0]const u8 = "Test sizes of various things";
    const container_test: [:0]const u8 = "Test container implementation";
    const readdir: [:0]const u8 = "Example program showing how to iterate directory entries";
    const dynamic: [:0]const u8 = "Example program showing how to allocator dynamic memory";
    const custom: [:0]const u8 = "Example program showing a complex custom address space";
    const allocators: [:0]const u8 = "Example program showing how to use many allocators";
    const mca: [:0]const u8 = "Example program useful for extracting section from assembly for machine code analysis";
    const treez: [:0]const u8 = "Example program useful for listing the contents of directories in a tree-like format";
    const itos: [:0]const u8 = "Example program useful for converting between a variety of integer formats and bases";
    const catz: [:0]const u8 = "Example program showing how to map and write a file to standard output";
    const cleanup: [:0]const u8 = "Example program showing more advanced operations on a mapped file";
    const hello: [:0]const u8 = "Example program showing various ways of printing 'Hello, world!'";
    const readelf: [:0]const u8 = "Example program (defunct) for parsing and displaying information about ELF binaries";
    const pathsplit: ?[:0]const u8 = null;
    const declprint: ?[:0]const u8 = null;
    const mg_aux: ?[:0]const u8 = null;
    const mg_touch: ?[:0]const u8 = "Creates placeholder files";
    const mg_specs: ?[:0]const u8 = "`serial*` for `[]const []const []const Specifier`";
    const mg_techs: ?[:0]const u8 = "`serial*` for `[]const []const []const Technique`";
    const mg_params: ?[:0]const u8 = "`serial*` for `[]const [] Specifier`";
    const mg_options: ?[:0]const u8 = "`serial*` for `[]const []const Technique`";
    const mg_abstract_specs: ?[:0]const u8 = "`serial*` for `[]const AbstractSpecification`";
    const mg_impl_detail: ?[:0]const u8 = "`serial*` for `[]const Implementation`";
    const mg_ctn_detail: ?[:0]const u8 = "`serial*` for `[]const Container`";
    const mg_new_type_specs: ?[:0]const u8 = "Generate data and container->reference deductions";
    const mg_container_kinds: ?[:0]const u8 = "Generate function kind switch functions for container functions";
    const mg_reference_impls: ?[:0]const u8 = "Generate reference implementations";
    const mg_container_impls: ?[:0]const u8 = "Generate container implementations";
};

pub fn testBuildProgram(allocator: *types.Allocator, builder: *Builder) !void {
    const exe_default: Builder.Extra = .{
        .build_cmd_init = define_exe(define_default(allocator.createIrreversible(types.BuildCommand))),
    };
    const obj_default: Builder.Extra = .{
        .build_cmd_init = define_obj(define_default(allocator.createIrreversible(types.BuildCommand))),
    };
    const g0: *Builder.Group = builder.addGroup(allocator, "g0");
    const builtin_test: *Builder.Target = try g0.addTarget(allocator, "builtin_test", "top/builtin-test.zig", exe_default);
    const meta_test: *Builder.Target = try g0.addTarget(allocator, "meta_test", "top/meta-test.zig", exe_default);
    const mem_test: *Builder.Target = try g0.addTarget(allocator, "mem_test", "top/mem-test.zig", exe_default);
    const algo_test: *Builder.Target = try g0.addTarget(allocator, "algo_test", "top/algo-test.zig", exe_default);
    const file_test: *Builder.Target = try g0.addTarget(allocator, "file_test", "top/file-test.zig", exe_default);
    const list_test: *Builder.Target = try g0.addTarget(allocator, "list_test", "top/list-test.zig", exe_default);
    const fmt_test: *Builder.Target = try g0.addTarget(allocator, "fmt_test", "top/fmt-test.zig", exe_default);
    const render_test: *Builder.Target = try g0.addTarget(allocator, "render_test", "top/render-test.zig", exe_default);
    const serial_test: *Builder.Target = try g0.addTarget(allocator, "serial_test", "top/serial-test.zig", exe_default);
    const thread_test: *Builder.Target = try g0.addTarget(allocator, "thread_test", "top/thread-test.zig", exe_default);
    const virtual_test: *Builder.Target = try g0.addTarget(allocator, "virtual_test", "top/virtual-test.zig", exe_default);
    const size_test: *Builder.Target = try g0.addTarget(allocator, "size_test", "test/size_per_config.zig", exe_default);
    const container_test: *Builder.Target = try g0.addTarget(allocator, "container_test", "top/container-test.zig", exe_default);
    const g1: *Builder.Group = builder.addGroup(allocator, "g1");
    const readdir: *Builder.Target = try g1.addTarget(allocator, "readdir", "examples/iterate_dir_entries.zig", exe_default);
    const dynamic: *Builder.Target = try g1.addTarget(allocator, "dynamic", "examples/dynamic_alloc.zig", exe_default);
    const custom: *Builder.Target = try g1.addTarget(allocator, "addrspace", "examples/custom_address_space.zig", exe_default);
    const allocators: *Builder.Target = try g1.addTarget(allocator, "allocators", "examples/allocators.zig", exe_default);
    const mca: *Builder.Target = try g1.addTarget(allocator, "mca", "examples/mca.zig", exe_default);
    const treez: *Builder.Target = try g1.addTarget(allocator, "treez", "examples/treez.zig", exe_default);
    const itos: *Builder.Target = try g1.addTarget(allocator, "itos", "examples/itos.zig", exe_default);
    const catz: *Builder.Target = try g1.addTarget(allocator, "catz", "examples/catz.zig", exe_default);
    const cleanup: *Builder.Target = try g1.addTarget(allocator, "cleanup", "examples/cleanup.zig", exe_default);
    const hello: *Builder.Target = try g1.addTarget(allocator, "hello", "examples/hello.zig", exe_default);
    const readelf: *Builder.Target = try g1.addTarget(allocator, "readelf", "examples/readelf.zig", exe_default);
    const pathsplit: *Builder.Target = try g1.addTarget(allocator, "pathsplit", "examples/pathsplit.zig", exe_default);
    const declprint: *Builder.Target = try g1.addTarget(allocator, "declprint", "examples/declprint.zig", exe_default);
    const mg: *Builder.Group = builder.addGroup(allocator, "g2");
    const mg_touch: *Builder.Target = try mg.addTarget(allocator, "mg_touch", "top/mem/touch-aux.zig", exe_default);
    const mg_specs: *Builder.Target = try mg.addTarget(allocator, "mg_specs", "top/mem/serial_specs.zig", obj_default);
    const mg_techs: *Builder.Target = try mg.addTarget(allocator, "mg_techs", "top/mem/serial_techs.zig", obj_default);
    const mg_params: *Builder.Target = try mg.addTarget(allocator, "mg_params", "top/mem/serial_params.zig", obj_default);
    const mg_options: *Builder.Target = try mg.addTarget(allocator, "mg_options", "top/mem/serial_options.zig", obj_default);
    const mg_abstract_specs: *Builder.Target = try mg.addTarget(allocator, "mg_abstract_specs", "top/mem/serial_abstract_specs.zig", obj_default);
    const mg_impl_detail: *Builder.Target = try mg.addTarget(allocator, "mg_impl_detail", "top/mem/serial_impl_detail.zig", obj_default);
    const mg_ctn_detail: *Builder.Target = try mg.addTarget(allocator, "mg_ctn_detail", "top/mem/serial_ctn_detail.zig", obj_default);
    const mg_new_type_specs: *Builder.Target = try mg.addTarget(allocator, "mg_new_type_specs", "top/mem/new_type_specs-aux.zig", exe_default);
    const mg_reference_impls: *Builder.Target = try mg.addTarget(allocator, "mg_reference_impls", "top/mem/reference_impls-aux.zig", exe_default);
    const mg_container_impls: *Builder.Target = try mg.addTarget(allocator, "mg_container_impls", "top/mem/container_impls-aux.zig", exe_default);

    mg_specs.descr = descr.mg_specs;
    mg_touch.descr = descr.mg_touch;
    mg_techs.descr = descr.mg_techs;
    mg_params.descr = descr.mg_params;
    mg_options.descr = descr.mg_options;
    mg_abstract_specs.descr = descr.mg_abstract_specs;
    mg_impl_detail.descr = descr.mg_impl_detail;
    mg_ctn_detail.descr = descr.mg_ctn_detail;
    mg_reference_impls.descr = descr.mg_reference_impls;
    mg_container_impls.descr = descr.mg_container_impls;

    builtin_test.descr = descr.builtin_test;
    meta_test.descr = descr.meta_test;
    mem_test.descr = descr.mem_test;
    algo_test.descr = descr.algo_test;
    file_test.descr = descr.file_test;
    list_test.descr = descr.list_test;
    fmt_test.descr = descr.fmt_test;
    render_test.descr = descr.render_test;
    serial_test.descr = descr.serial_test;
    thread_test.descr = descr.thread_test;
    virtual_test.descr = descr.virtual_test;
    size_test.descr = descr.size_test;
    container_test.descr = descr.container_test;
    readdir.descr = descr.readdir;
    dynamic.descr = descr.dynamic;
    custom.descr = descr.custom;
    allocators.descr = descr.allocators;
    mca.descr = descr.mca;
    treez.descr = descr.treez;
    itos.descr = descr.itos;
    catz.descr = descr.catz;
    cleanup.descr = descr.cleanup;
    hello.descr = descr.hello;
    readelf.descr = descr.readelf;
    pathsplit.descr = descr.pathsplit;
    declprint.descr = descr.declprint;

    const g3 = builder.addGroup(allocator, "g3");
    const t2: *Builder.Target = try g3.addTarget(allocator, "obj0", "test/src/obj0.zig", obj_default);
    const t3: *Builder.Target = try g3.addTarget(allocator, "obj1", "test/src/obj1.zig", obj_default);
    const t4: *Builder.Target = try g3.addTarget(allocator, "obj2", "test/src/obj2.zig", obj_default);
    const t5: *Builder.Target = try g3.addTarget(allocator, "obj3", "test/src/obj3.zig", obj_default);
    const t6: *Builder.Target = try g3.addTarget(allocator, "obj4", "test/src/obj4.zig", obj_default);
    const t7: *Builder.Target = try g3.addTarget(allocator, "obj5", "test/src/obj5.zig", obj_default);
    const t1: *Builder.Target = try g3.addTarget(allocator, "lib0", "test/src/lib0.zig", obj_default);
    const t0: *Builder.Target = try g3.addTarget(allocator, "lib1", "test/src/lib1.zig", obj_default);
    const t: *Builder.Target = try g3.addTarget(allocator, "bin", "test/src/main.zig", exe_default);
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
    mg_container_impls.dependOnRun(allocator, builder.createTarget(allocator, "mg_container_kinds", "top/mem/container_kinds-aux.zig", exe_default));
    mg_new_type_specs.dependOnObject(allocator, mg_options);
    mg_new_type_specs.dependOnObject(allocator, mg_params);
    mg_new_type_specs.dependOnObject(allocator, mg_techs);
    mg_new_type_specs.dependOnObject(allocator, mg_specs);
    mg_new_type_specs.dependOnObject(allocator, mg_ctn_detail);
    mg_new_type_specs.dependOnObject(allocator, mg_impl_detail);
    mg_container_impls.dependOnObject(allocator, mg_ctn_detail);
    mg_container_impls.dependOnObject(allocator, mg_impl_detail);
    mg_reference_impls.dependOnObject(allocator, mg_ctn_detail);
    mg_reference_impls.dependOnObject(allocator, mg_impl_detail);
}
fn testBuildRunner(args: [][*:0]u8, vars: [][*:0]u8, comptime main_fn: fn (*types.Allocator, *Builder) anyerror!void) !void {
    var address_space: types.AddressSpace = .{};
    var thread_space: types.ThreadSpace = .{};
    var allocator: types.Allocator = try meta.wrap(types.Allocator.init(&address_space, types.thread_count));
    defer allocator.deinit(&address_space, types.thread_count);
    const cmds: [][*:0]u8 = args[5..];
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try main_fn(&allocator, &builder);
    var target_task: build.Task = .build;
    for (cmds) |arg| {
        const command: []const u8 = meta.manyToSlice(arg);
        if (mach.testEqualMany8(command, "build")) {
            target_task = .build;
        } else if (mach.testEqualMany8(command, "run")) {
            target_task = .run;
        } else if (mach.testEqualMany8(command, "show")) {
            return Builder.debug.builderCommandNotice(&builder, false, false, false);
        } else if (mach.testEqualMany8(command, "show-all")) {
            return Builder.debug.builderCommandNotice(&builder, true, true, true);
        } else for (builder.groups()) |group| {
            if (mach.testEqualMany8(command, group.name)) {
                try meta.wrap(group.acquireLock(&address_space, &thread_space, &allocator, target_task));
            } else for (group.targets()) |target| {
                if (mach.testEqualMany8(command, target.name)) {
                    try meta.wrap(target.acquireLock(&address_space, &thread_space, &allocator, &builder, target_task, types.thread_count, 0));
                }
            }
        }
    }
}
const Types = struct {
    TaskData: type,
    Allocator: type,
    AddressSpace: type,
    Array: type,
};
fn getTypes(comptime builder_fn: anytype) Types {
    const TaskData = @typeInfo(@TypeOf(builder_fn)).Fn.params[0].type;
    const Array = meta.Child(@typeInfo(@TypeOf(builder_fn)).Fn.params[1].type.?);
    return .{
        .Array = Array,
        .TaskData = meta.Child(TaskData.?),
        .Allocator = meta.Child(@typeInfo(@TypeOf(Array.init)).Fn.params[0].type.?),
        .AddressSpace = meta.Child(@typeInfo(@TypeOf(Array.init)).Fn.params[0].type.?).AddressSpace,
    };
}
fn testDirectCommandLineUsage() void {
    const env = @import("env");
    const T = getTypes(command_line.buildWrite);
    var address_space: T.AddressSpace = .{};
    var allocator: T.Allocator = T.Allocator.init(&address_space, 0);
    defer allocator.deinit(&address_space, 0);
    var array: T.Array = T.Array.init(&allocator, 4096);
    defer array.deinit(&allocator);
    var cmd: T.TaskData = .{
        .kind = .exe,
        .emit_bin = .{ .yes = .{ .absolute = env.build_root, .relative = "zig-out/bin/test_output" } },
    };
    command_line.buildWrite(&cmd, &array);
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try testBuildRunner(args, vars, testBuildProgram);
}
