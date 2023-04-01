const lit = @import("./lit.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const thread = @import("./thread.zig");
const preset = @import("./preset.zig");
const virtual = @import("./virtual.zig");
const builtin = @import("./builtin.zig");

const Rng = file.DeviceRandomBytes(4096);

const build = @import("./build2.zig");
const types = @import("./build/types2.zig");
const env = @import("env");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;
pub const runtime_assertions: bool = false;

const Builder = build.GenericBuilder(.{
    .errors = preset.builder.errors.noexcept,
    .logging = preset.builder.logging.silent,
});

pub const AddressSpace = types.AddressSpace;
pub const ThreadSpace = types.ThreadSpace;
pub const Allocator = types.Allocator;

const deps: []const types.ModuleDependency = &.{
    .{ .name = "zig_lib" },
    .{ .name = "@build" },
    .{ .name = "env" },
};
const modules: []const types.Module = &.{
    .{ .name = "zig_lib", .path = "zig_lib.zig" },
    .{ .name = "@build", .path = "build.zig" },
    .{ .name = "env", .path = "zig-cache/env.zig" },
};

const extra = .{
    .omit_frame_pointer = false,
    .single_threaded = true,
    .static = true,
    .code_model = .large,
    .enable_cache = true,
    .function_sections = true,
    .compiler_rt = false,
    .strip = true,
    .image_base = 0x10000,
    .mode = .ReleaseSmall,
    .reference_trace = true,
    .dependencies = deps,
    .modules = modules,
};

pub fn buildMainReal(address_space: *AddressSpace, thread_space: *ThreadSpace, allocator: *Allocator, builder: *Builder) !void {
    const tests: *Builder.Group = builder.addGroup(allocator, "tests");
    const builtin_test: *Builder.Target = tests.addTarget(allocator, .exe, "builtin_test", "top/builtin-test.zig", extra);
    const meta_test: *Builder.Target = tests.addTarget(allocator, .exe, "meta_test", "top/meta-test.zig", extra);
    const mem_test: *Builder.Target = tests.addTarget(allocator, .exe, "mem_test", "top/mem-test.zig", extra);
    const algo_test: *Builder.Target = tests.addTarget(allocator, .exe, "algo_test", "top/algo-test.zig", extra);
    const file_test: *Builder.Target = tests.addTarget(allocator, .exe, "file_test", "top/file-test.zig", extra);
    const list_test: *Builder.Target = tests.addTarget(allocator, .exe, "list_test", "top/list-test.zig", extra);
    const fmt_test: *Builder.Target = tests.addTarget(allocator, .exe, "fmt_test", "top/fmt-test.zig", extra);
    const render_test: *Builder.Target = tests.addTarget(allocator, .exe, "render_test", "top/render-test.zig", extra);
    const serial_test: *Builder.Target = tests.addTarget(allocator, .exe, "serial_test", "top/serial-test.zig", extra);
    const thread_test: *Builder.Target = tests.addTarget(allocator, .exe, "thread_test", "top/thread-test.zig", extra);
    const virtual_test: *Builder.Target = tests.addTarget(allocator, .exe, "virtual_test", "top/virtual-test.zig", extra);
    const size_test: *Builder.Target = tests.addTarget(allocator, .exe, "size_test", "test/size_per_config.zig", extra);
    const container_test: *Builder.Target = tests.addTarget(allocator, .exe, "container_test", "top/container-test.zig", extra);

    try meta.wrap(tests.acquireGroupLock(address_space, thread_space, allocator, .build));

    _ = builtin_test;
    _ = meta_test;
    _ = mem_test;
    _ = algo_test;
    _ = file_test;
    _ = list_test;
    _ = fmt_test;
    _ = render_test;
    _ = serial_test;
    _ = thread_test;
    _ = virtual_test;
    _ = size_test;
    _ = container_test;
}
pub fn buildMain(address_space: *AddressSpace, thread_space: *ThreadSpace, allocator: *Allocator, builder: *Builder) !void {
    const t2: *Builder.Target = builder.addTarget(allocator, .obj, "obj0", "src/obj0.zig", extra);
    const t3: *Builder.Target = builder.addTarget(allocator, .obj, "obj1", "src/obj1.zig", extra);
    const t4: *Builder.Target = builder.addTarget(allocator, .obj, "obj2", "src/obj2.zig", extra);
    const t5: *Builder.Target = builder.addTarget(allocator, .obj, "obj3", "src/obj3.zig", extra);
    const t6: *Builder.Target = builder.addTarget(allocator, .obj, "obj4", "src/obj4.zig", extra);
    const t7: *Builder.Target = builder.addTarget(allocator, .obj, "obj5", "src/obj5.zig", extra);

    const t1: *Builder.Target = builder.addTarget(allocator, .lib, "lib0", "src/lib0.zig", extra);
    t1.dependOnBuild(allocator, t2);
    t1.dependOnBuild(allocator, t3);
    t1.dependOnBuild(allocator, t4);

    const t0: *Builder.Target = builder.addTarget(allocator, .lib, "lib1", "src/lib1.zig", extra);
    t0.dependOnBuild(allocator, t1);
    t0.dependOnBuild(allocator, t2);
    t0.dependOnBuild(allocator, t3);

    const t: *Builder.Target = builder.addTarget(allocator, .exe, "bin", "src/main.zig", extra);
    t.dependOnBuild(allocator, t0);
    t.dependOnBuild(allocator, t5);
    t.dependOnBuild(allocator, t6);
    t.dependOnBuild(allocator, t7);

    builtin.assert(t.lock.atomicTransform(.build, .ready, .blocking));
    try meta.wrap(builder.acquireTargetLock(address_space, thread_space, allocator, t, .build, null, 0));
}

pub fn main(args: anytype, vars: anytype) !void {
    var address_space: AddressSpace = .{};
    var thread_space: ThreadSpace = .{};
    var allocator: types.Allocator = types.Allocator.init(&address_space, types.thread_count);
    defer allocator.deinit(&address_space, 0);
    var builder: Builder = try meta.wrap(Builder.init(env.zig_exe, env.build_root, env.cache_dir, env.global_cache_dir, args, vars));
    try buildMainReal(&address_space, &thread_space, &allocator, &builder);
}
