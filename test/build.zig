const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const gen = zl.gen;
const sys = zl.sys;
const fmt = zl.fmt;
const proc = zl.proc;
const spec = zl.spec;
const file = zl.file;
const meta = zl.meta;
const debug = zl.debug;
const build = zl.build;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const Builder = build.GenericBuilder(.{
    .errors = build.spec.errors.kill(),
    .options = .{
        .max_thread_count = 8,
        .extensions_policy = .emergency,
        .max_error_count = 1,
    },
});
pub const AbsoluteState = struct {
    home: [:0]u8,
    cwd: [:0]u8,
    proj: [:0]u8,
    pid: u16,
};
pub const message_style = "\x1b[93m";
pub const enable_debugging: bool = true;
pub const never_exit_group: bool = false;
pub const want_stack_traces: bool = enable_debugging;
pub const logging_override: debug.Logging.Override = .{
    .Attempt = enable_debugging,
    .Success = enable_debugging,
    .Acquire = enable_debugging,
    .Release = enable_debugging,
    .Error = enable_debugging,
    .Fault = enable_debugging,
};
pub const logging_default: debug.Logging.Default = .{
    .Attempt = enable_debugging,
    .Success = enable_debugging,
    .Acquire = enable_debugging,
    .Release = enable_debugging,
    .Error = enable_debugging,
    .Fault = enable_debugging,
};
pub const signal_handlers = .{
    .IllegalInstruction = enable_debugging,
    .BusError = enable_debugging,
    .FloatingPointError = enable_debugging,
    .Trap = enable_debugging,
    .SegmentationFault = enable_debugging,
};
pub const trace: debug.Trace = .{
    .Error = enable_debugging,
    .Fault = enable_debugging,
    .Signal = enable_debugging,
    .options = .{},
};
const Node = Builder.Node;
pub fn buildRunner(args: [][*:0]u8, vars: [][*:0]u8, comptime any: anytype) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.fromArena(
        Builder.AddressSpace.arena(Builder.max_thread_count),
    );
    if (args.len < 5) {
        zl.proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    const top: *Node = Node.init(&allocator, "top", args, vars);
    try meta.wrap(any(&allocator, top));
    try zl.meta.wrap(Builder.processCommands(&address_space, &thread_space, &allocator, top));
    allocator.unmapAll();
}
const text =
    \\const zl = @import("../../../zig_lib.zig");
    \\pub usingnamespace zl.start;
    \\
;
fn testConfig(allocator: *build.Allocator, top: *Node) !void {
    top.addConfigString(allocator, "zig_exe", top.zigExe());
    var buf1: [4096]u8 = undefined;
    var len: usize = top.getConfigs()[0].formatWriteBuf(&buf1);
    try debug.expect(mem.testEqualManyIn(u8, top.zigExe(), buf1[0..len]));
}
fn buildMain(allocator: *build.Allocator, top: *Node) !void {
    @setRuntimeSafety(false);
    const test_dir_fd: usize = try file.path(.{}, .{}, "test");
    file.makeDirAt(.{}, test_dir_fd, "build", file.mode.directory) catch |err| {
        if (err != error.FileExists) {
            return err;
        }
    };
    const test_build_dir_fd: usize = try file.pathAt(.{}, .{}, test_dir_fd, "build");
    file.makeDirAt(.{}, test_build_dir_fd, "stress", file.mode.directory) catch |err| {
        if (err != error.FileExists) {
            return err;
        }
    };
    const build_exe_cmd: build.BuildCommand = .{ .kind = .exe, .mode = .ReleaseSmall, .compiler_rt = false };
    const build_obj_cmd: build.BuildCommand = .{ .kind = .lib, .mode = .ReleaseSmall, .compiler_rt = false, .dynamic = true };
    const stress_dir_fd: usize = try file.pathAt(.{}, .{}, test_build_dir_fd, "stress");
    const node: *Node = top.addBuild(allocator, build_exe_cmd, "exe", "test/build/stress/exe.zig");
    try gen.truncateFile(.{ .return_type = void }, "test/build/stress/exe.zig", text ++ "pub fn main() void {}");
    const f = "test/build/stress/f_";
    var buf: [8192]u8 = undefined;
    for (0..10) |x| {
        var ud64: fmt.Type.Ud64 = .{ .value = x };
        var ptr: [*]u8 = &buf;
        ptr = fmt.strcpyEqu(ptr, f);
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = 0;
        const x_name: [:0]const u8 = mem.terminate(buf[f.len -% 2 ..], 0);
        ptr = fmt.strcpyEqu(ptr, ".zig");
        ptr[0] = 0;
        const x_root: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
        const x_node: *Node = top.addBuild(allocator, build_obj_cmd, x_name, x_root);
        ptr = &buf;
        ptr = fmt.strcpyEqu(ptr, text);
        ptr = fmt.strcpyEqu(ptr, "export fn func_");
        ptr += ud64.formatWriteBuf(ptr);
        ptr = fmt.strcpyEqu(ptr, "() void {}");
        ptr[0] = 0;
        const x_file: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
        try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, x_node.getPaths()[1].concatenate(allocator), x_file);
        node.dependOn(allocator, x_node);
        for (0..10) |y| {
            ud64.value = y + 10 *% x;
            ptr = &buf;
            ptr = fmt.strcpyEqu(ptr, f);
            ptr += ud64.formatWriteBuf(ptr);
            ptr[0] = 0;
            const y_name: [:0]const u8 = mem.terminate(buf[f.len -% 2 ..], 0);
            ptr = fmt.strcpyEqu(ptr, ".zig");
            ptr[0] = 0;
            const y_root: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
            const y_node: *Node = top.addBuild(allocator, build_obj_cmd, y_name, y_root);
            ptr = &buf;
            ptr = fmt.strcpyEqu(ptr, text);
            ptr = fmt.strcpyEqu(ptr, "export fn func_");
            ptr += ud64.formatWriteBuf(ptr);
            ptr = fmt.strcpyEqu(ptr, "() void {}");
            ptr[0] = 0;
            const y_file: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
            try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, y_node.getPaths()[1].concatenate(allocator), y_file);
            ptr = &buf;
            ptr = fmt.strcpyEqu(ptr, f);
            ptr += ud64.formatWriteBuf(ptr);
            ptr = fmt.strcpyEqu(ptr, "_c");
            ptr[0] = 0;
            const y_name_c: [:0]const u8 = mem.terminate(buf[f.len -% 2 ..], 0);
            ptr = fmt.strcpyEqu(ptr, ".c");
            ptr[0] = 0;
            const y_root_c: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
            const y_node_c: *Node = top.addBuild(allocator, build_obj_cmd, y_name_c, y_root_c);
            ptr = &buf;
            ptr = fmt.strcpyEqu(ptr, "int c_func_");
            ptr += ud64.formatWriteBuf(ptr);
            ptr = fmt.strcpyEqu(ptr, "() {}");
            ptr[0] = 0;
            const y_file_c: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
            try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, y_node_c.getPaths()[1].concatenate(allocator), y_file_c);
            x_node.dependOn(allocator, y_node);
            x_node.dependOn(allocator, y_node_c);
            for (0..10) |z| {
                ud64.value = z +% (y *% 10) + (100 *% x);
                ptr = &buf;
                ptr = fmt.strcpyEqu(ptr, f);
                ptr += ud64.formatWriteBuf(ptr);
                ptr[0] = 0;
                const z_name: [:0]const u8 = mem.terminate(buf[f.len -% 2 ..], 0);
                ptr = fmt.strcpyEqu(ptr, ".zig");
                ptr[0] = 0;
                const z_root: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
                const z_node: *Node = top.addBuild(allocator, build_obj_cmd, z_name, z_root);
                ptr = &buf;
                ptr = fmt.strcpyEqu(ptr, text);
                ptr = fmt.strcpyEqu(ptr, "export fn func_");
                ptr += ud64.formatWriteBuf(ptr);
                ptr = fmt.strcpyEqu(ptr, "() void {}");
                ptr[0] = 0;
                const z_file: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
                try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, z_node.getPaths()[1].concatenate(allocator), z_file);
                ptr = &buf;
                ptr = fmt.strcpyEqu(ptr, f);
                ptr += ud64.formatWriteBuf(ptr);
                ptr = fmt.strcpyEqu(ptr, "_c");
                ptr[0] = 0;
                const z_name_c: [:0]const u8 = mem.terminate(buf[f.len -% 2 ..], 0);
                ptr = fmt.strcpyEqu(ptr, ".c");
                ptr[0] = 0;
                const z_root_c: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
                const z_node_c: *Node = top.addBuild(allocator, build_obj_cmd, z_name_c, z_root_c);
                ptr = &buf;
                ptr = fmt.strcpyEqu(ptr, "int c_func_");
                ptr += ud64.formatWriteBuf(ptr);
                ptr = fmt.strcpyEqu(ptr, "() {}");
                ptr[0] = 0;
                const z_file_c: [:0]const u8 = buf[0..fmt.strlen(ptr, &buf) :0];
                try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, z_node_c.getPaths()[1].concatenate(allocator), z_file_c);
                y_node.dependOn(allocator, z_node);
                y_node.dependOn(allocator, z_node_c);
            }
        }
    }
}
const SingleThreaded = struct {
    fn buildMain(allocator: *build.Allocator, top: *build.Node) !void {
        _ = top.addBuild(allocator, .{ .kind = .exe }, "main", "./build");
    }
};
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try buildRunner(args, vars, buildMain);
}
