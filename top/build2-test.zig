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

const extra = .{
    .omit_frame_pointer = false,
    .single_threaded = true,
    .static = true,
    .code_model = .small,
    .enable_cache = true,
    .function_sections = true,
    .compiler_rt = false,
    .strip = true,
    .image_base = 0x10000,
    .mode = .ReleaseSmall,
    .reference_trace = true,
    .dependencies = &.{
        .{ .name = "zig_lib" },
        .{ .name = "@build" },
        .{ .name = "env" },
    },
    .modules = &.{
        .{ .name = "zig_lib", .path = "zig_lib.zig" },
        .{ .name = "@build", .path = "build.zig" },
        .{ .name = "env", .path = "zig-cache/env.zig" },
    },
};
pub fn testBuildProgram(allocator: *types.Allocator, builder: *Builder) !void {
    const g0: *Builder.Group = builder.addGroup(allocator, "g0");
    const builtin_test: *Builder.Target = g0.addTarget(allocator, .exe, "builtin_test", "top/builtin-test.zig", extra);
    const meta_test: *Builder.Target = g0.addTarget(allocator, .exe, "meta_test", "top/meta-test.zig", extra);
    const mem_test: *Builder.Target = g0.addTarget(allocator, .exe, "mem_test", "top/mem-test.zig", extra);
    const algo_test: *Builder.Target = g0.addTarget(allocator, .exe, "algo_test", "top/algo-test.zig", extra);
    const file_test: *Builder.Target = g0.addTarget(allocator, .exe, "file_test", "top/file-test.zig", extra);
    const list_test: *Builder.Target = g0.addTarget(allocator, .exe, "list_test", "top/list-test.zig", extra);
    const fmt_test: *Builder.Target = g0.addTarget(allocator, .exe, "fmt_test", "top/fmt-test.zig", extra);
    const render_test: *Builder.Target = g0.addTarget(allocator, .exe, "render_test", "top/render-test.zig", extra);
    const serial_test: *Builder.Target = g0.addTarget(allocator, .exe, "serial_test", "top/serial-test.zig", extra);
    const thread_test: *Builder.Target = g0.addTarget(allocator, .exe, "thread_test", "top/thread-test.zig", extra);
    const virtual_test: *Builder.Target = g0.addTarget(allocator, .exe, "virtual_test", "top/virtual-test.zig", extra);
    const size_test: *Builder.Target = g0.addTarget(allocator, .exe, "size_test", "test/size_per_config.zig", extra);
    const container_test: *Builder.Target = g0.addTarget(allocator, .exe, "container_test", "top/container-test.zig", extra);

    const g1: *Builder.Group = builder.addGroup(allocator, "g1");
    const readdir: *Builder.Target = g1.addTarget(allocator, .exe, "readdir", "examples/iterate_dir_entries.zig", extra);
    const dynamic: *Builder.Target = g1.addTarget(allocator, .exe, "dynamic", "examples/dynamic_alloc.zig", extra);
    const custom: *Builder.Target = g1.addTarget(allocator, .exe, "addrspace", "examples/custom_address_space.zig", extra);
    const allocators: *Builder.Target = g1.addTarget(allocator, .exe, "allocators", "examples/allocators.zig", extra);
    const mca: *Builder.Target = g1.addTarget(allocator, .exe, "mca", "examples/mca.zig", extra);
    const treez: *Builder.Target = g1.addTarget(allocator, .exe, "treez", "examples/treez.zig", extra);
    const itos: *Builder.Target = g1.addTarget(allocator, .exe, "itos", "examples/itos.zig", extra);
    const catz: *Builder.Target = g1.addTarget(allocator, .exe, "catz", "examples/catz.zig", extra);
    const cleanup: *Builder.Target = g1.addTarget(allocator, .exe, "cleanup", "examples/cleanup.zig", extra);
    const hello: *Builder.Target = g1.addTarget(allocator, .exe, "hello", "examples/hello.zig", extra);
    const readelf: *Builder.Target = g1.addTarget(allocator, .exe, "readelf", "examples/readelf.zig", extra);
    const pathsplit: *Builder.Target = g1.addTarget(allocator, .exe, "pathsplit", "examples/pathsplit.zig", extra);
    const declprint: *Builder.Target = g1.addTarget(allocator, .exe, "declprint", "examples/declprint.zig", extra);

    const mg_aux: *Builder.Group = builder.addGroup(allocator, "g2");
    const mg_touch: *Builder.Target = mg_aux.addTarget(allocator, .exe, "mg_touch", "top/mem/touch-aux.zig", extra);
    const mg_specs: *Builder.Target = mg_aux.addTarget(allocator, .obj, "mg_specs", "top/mem/serial_specs.zig", extra);
    const mg_techs: *Builder.Target = mg_aux.addTarget(allocator, .obj, "mg_techs", "top/mem/serial_techs.zig", extra);
    const mg_params: *Builder.Target = mg_aux.addTarget(allocator, .obj, "mg_params", "top/mem/serial_params.zig", extra);
    const mg_options: *Builder.Target = mg_aux.addTarget(allocator, .obj, "mg_options", "top/mem/serial_options.zig", extra);
    const mg_abstract_specs: *Builder.Target = mg_aux.addTarget(allocator, .obj, "mg_abstract_specs", "top/mem/serial_abstract_specs.zig", extra);
    const mg_impl_detail: *Builder.Target = mg_aux.addTarget(allocator, .obj, "mg_impl_detail", "top/mem/serial_impl_detail.zig", extra);
    const mg_ctn_detail: *Builder.Target = mg_aux.addTarget(allocator, .obj, "mg_ctn_detail", "top/mem/serial_ctn_detail.zig", extra);
    const mg_new_type_specs: *Builder.Target = mg_aux.addTarget(allocator, .exe, "mg_new_type_specs", "top/mem/new_type_specs-aux.zig", extra);
    const mg_container_kinds: *Builder.Target = mg_aux.addTarget(allocator, .exe, "mg_container_kinds", "top/mem/container_kinds-aux.zig", extra);
    const mg_reference_impls: *Builder.Target = mg_aux.addTarget(allocator, .exe, "mg_reference_impls", "top/mem/reference_impls-aux.zig", extra);
    const mg_container_impls: *Builder.Target = mg_aux.addTarget(allocator, .exe, "mg_container_impls", "top/mem/container_impls-aux.zig", extra);

    const group = builder.addGroup(allocator, "g3");
    const t2: *Builder.Target = group.addTarget(allocator, .obj, "obj0", "test/src/obj0.zig", extra);
    const t3: *Builder.Target = group.addTarget(allocator, .obj, "obj1", "test/src/obj1.zig", extra);
    const t4: *Builder.Target = group.addTarget(allocator, .obj, "obj2", "test/src/obj2.zig", extra);
    const t5: *Builder.Target = group.addTarget(allocator, .obj, "obj3", "test/src/obj3.zig", extra);
    const t6: *Builder.Target = group.addTarget(allocator, .obj, "obj4", "test/src/obj4.zig", extra);
    const t7: *Builder.Target = group.addTarget(allocator, .obj, "obj5", "test/src/obj5.zig", extra);
    const t1: *Builder.Target = group.addTarget(allocator, .obj, "lib0", "test/src/lib0.zig", extra);
    t1.dependOnObject(allocator, t2);
    t1.dependOnObject(allocator, t3);
    t1.dependOnObject(allocator, t4);
    const t0: *Builder.Target = group.addTarget(allocator, .obj, "lib1", "test/src/lib1.zig", extra);
    t0.dependOnObject(allocator, t1);
    t0.dependOnObject(allocator, t2);
    t0.dependOnObject(allocator, t3);
    const t: *Builder.Target = group.addTarget(allocator, .exe, "bin", "test/src/main.zig", extra);
    t.dependOnObject(allocator, t0);
    t.dependOnObject(allocator, t5);
    t.dependOnObject(allocator, t6);
    t.dependOnObject(allocator, t7);

    mg_container_kinds.dependOnRun(allocator, mg_touch);
    mg_container_impls.dependOnRun(allocator, mg_container_kinds);
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

    _ = .{
        readdir,      dynamic,           custom,         allocators,
        mca,          treez,             itos,           catz,
        cleanup,      hello,             readelf,        pathsplit,
        declprint,    mg_abstract_specs, builtin_test,   meta_test,
        mem_test,     algo_test,         file_test,      list_test,
        fmt_test,     render_test,       serial_test,    thread_test,
        virtual_test, size_test,         container_test,
    };
}

fn testBuildRunner(args: [][*:0]u8, vars: [][*:0]u8, comptime main_fn: fn (*types.Allocator, *Builder) anyerror!void) !void {
    var address_space: types.AddressSpace = .{};
    var thread_space: types.ThreadSpace = .{};
    var allocator: types.Allocator = types.Allocator.init(&address_space, types.thread_count);
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
            Builder.debug.builderCommandNotice(&builder);
        } else for (builder.groups()) |*group| {
            if (mach.testEqualMany8(command, group.name)) {
                try meta.wrap(group.acquireLock(&address_space, &thread_space, &allocator, target_task));
            } else for (group.targets()) |*target| {
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
fn do_nothing(_: [][*:0]u8, _: [][*:0]u8) void {}

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try testBuildRunner(args, vars, testBuildProgram);
}
