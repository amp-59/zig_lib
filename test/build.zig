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
pub usingnamespace zl.start;

pub const Builder = build.GenericBuilder(.{ .options = .{ .max_thread_count = 8 } });
pub const message_style = "";
pub const enable_debugging: bool = true;
pub const exec_mode = .Run;
pub const want_stack_traces: bool = enable_debugging;
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
fn buildRunner(args: [][*:0]u8, vars: [][*:0]u8, comptime Container: anytype) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.init_arena(
        Builder.AddressSpace.arena(Builder.specification.options.max_thread_count),
    );
    defer allocator.unmapAll();
    if (args.len < 5) {
        proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    const toplevel: *build.Node = try meta.wrap(build.Node.create(&allocator, "toplevel", args, vars));
    try meta.wrap(
        Container.buildMain(&allocator, toplevel),
    );
    Builder.updateCommands(&allocator, toplevel);
    try meta.wrap(
        Builder.processCommands(&address_space, &thread_space, &allocator, toplevel),
    );
}
const text =
    \\const zl = @import("../../../zig_lib.zig");
    \\pub usingnamespace zl.start;
    \\
;
fn ManyCAndZigBuildTasks(comptime options: anytype) type {
    return struct {
        const Node = build.GenericNode(options);
        fn buildMain(allocator: *build.Allocator, toplevel: *Node) !void {
            @setEvalBranchQuota(~@as(u32, 0));
            const test_dir_fd: usize = try file.path(.{}, "test");
            file.makeDirAt(.{}, test_dir_fd, "build", file.mode.directory) catch |err| {
                if (err != error.FileExists) {
                    return err;
                }
            };
            const test_build_dir_fd: usize = try file.pathAt(.{}, test_dir_fd, "build");
            file.makeDirAt(.{}, test_build_dir_fd, "stress", file.mode.directory) catch |err| {
                if (err != error.FileExists) {
                    return err;
                }
            };
            const build_exe_cmd: build.BuildCommand = .{ .kind = .exe, .mode = .ReleaseSmall, .compiler_rt = false };
            const build_obj_cmd: build.BuildCommand = .{ .kind = .obj, .mode = .ReleaseSmall, .compiler_rt = false };
            const stress_dir_fd: usize = try file.pathAt(.{}, test_build_dir_fd, "stress");
            const node: *Node = toplevel.addBuild(allocator, build_exe_cmd, "top", "test/build/stress/top.zig");
            try gen.truncateFile(.{ .return_type = void }, "test/build/stress/top.zig", text ++ "pub fn main() void {}");
            inline for (0..4) |x| {
                const x_s = comptime fmt.cx(x);
                const x_root = "f_" ++ x_s ++ ".zig";
                const x_node: *Node = toplevel.addBuild(allocator, build_obj_cmd, x_s, "test/build/stress/" ++ x_root);
                x_node.flags.is_hidden = true;
                node.dependOn(allocator, x_node);
                try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, x_root, text ++ "export fn func_" ++ x_s ++ "() void {}");
                inline for (0..4) |y| {
                    const y_s = x_s ++ comptime fmt.cx(y);
                    const y_root = "f_" ++ y_s ++ ".zig";
                    const y_root_c = "f_" ++ y_s ++ ".c";
                    const y_node: *Node = toplevel.addBuild(allocator, build_obj_cmd, y_s, "test/build/stress/" ++ y_root);
                    const y_node_c: *Node = toplevel.addBuild(allocator, build_obj_cmd, y_s ++ "_c", "test/build/stress/" ++ y_root_c);
                    try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, y_root, text ++ "export fn func_" ++ y_s ++ "() void {}");
                    try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, y_root_c, "void c_func_" ++ y_s ++ "() {}");
                    y_node.flags.is_hidden = true;
                    y_node_c.flags.is_hidden = true;
                    x_node.dependOn(allocator, y_node);
                    x_node.dependOn(allocator, y_node_c);
                    inline for (0..4) |z| {
                        const z_s = y_s ++ comptime fmt.cx(z);
                        const z_root = "f_" ++ z_s ++ ".zig";
                        const z_root_c = "f_" ++ z_s ++ ".c";
                        const z_node: *Node = toplevel.addBuild(allocator, build_obj_cmd, z_s, "test/build/stress/" ++ z_root);
                        const z_node_c: *Node = toplevel.addBuild(allocator, build_obj_cmd, z_s ++ "_c", "test/build/stress/" ++ z_root_c);
                        try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, z_root, text ++ "export fn func_" ++ z_s ++ "() void {}");
                        try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, z_root_c, "void c_func_" ++ z_s ++ "() {}");
                        z_node.flags.is_hidden = true;
                        z_node_c.flags.is_hidden = true;
                        y_node.dependOn(allocator, z_node);
                        y_node.dependOn(allocator, z_node_c);
                    }
                }
            }
        }
    };
}
const SingleThreaded = struct {
    fn buildMain(allocator: *build.Allocator, toplevel: *build.Node) !void {
        _ = toplevel.addBuild(allocator, .{ .kind = .exe }, "main", "./build");
    }
};
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    try buildRunner(args, vars, SingleThreaded);
}
