const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const gen = zl.gen;
const sys = zl.sys;
const proc = zl.proc;
const spec = zl.spec;
const file = zl.file;
const meta = zl.meta;
const build = zl.build;
const builtin = zl.builtin;

pub usingnamespace zl.start;

const Node = build.GenericNode(.{
    .options = .{ .max_thread_count = 8 },
});
pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;
pub const logging_default: builtin.Logging.Default = .{
    .Attempt = true,
    .Success = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Fault = true,
};
pub const signal_handlers = .{
    .IllegalInstruction = true,
    .BusError = true,
    .FloatingPointError = true,
    .Trap = true,
    .SegmentationFault = true,
};
pub const trace: builtin.Trace = .{
    .Error = true,
    .Fault = true,
    .Signal = true,
    .options = .{},
};
pub const discard_errors = true;
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    Node.initState(args, vars);
    const toplevel: *Node = try meta.wrap(Node.init(&allocator));
    Node.initSpecialNodes(&allocator, toplevel);
    try meta.wrap(
        buildMain(&allocator, toplevel),
    );
    Node.updateCommands(&allocator, toplevel, toplevel);
    try meta.wrap(
        Node.processCommands(&address_space, &thread_space, &allocator, toplevel),
    );
}
const text =
    \\const zl = @import("../../zig_lib.zig");
    \\pub usingnamespace zig_lib.proc.start;
    \\
;
fn buildMain(allocator: *build.Allocator, toplevel: *Node) !void {
    @setEvalBranchQuota(~@as(u32, 0));
    const test_dir_fd: u64 = try file.path(.{}, "test");
    file.makeDirAt(.{}, test_dir_fd, "stress", file.mode.directory) catch |err| {
        if (err != error.FileExists) {
            return err;
        }
    };
    const stress_dir_fd: u64 = try file.pathAt(.{}, test_dir_fd, "stress");
    const node: *Node = toplevel.addBuild(allocator, .{ .kind = .exe }, "top", "test/stress/top.zig");
    try gen.truncateFile(.{ .return_type = void }, "test/stress/top.zig", text ++
        \\pub fn main() void {}
    );
    inline for (0..10) |x| {
        const x_s = comptime builtin.fmt.cx(x);
        const x_root = "f_" ++ x_s ++ ".zig";
        const x_node: *Node = toplevel.addBuild(allocator, .{ .kind = .obj }, x_s, "test/stress/" ++ x_root);
        x_node.flags.is_hidden = true;
        node.dependOnObject(allocator, x_node);
        try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, x_root, text ++ "export fn func_" ++ x_s ++ "() void {}");
        inline for (0..10) |y| {
            const y_s = x_s ++ comptime builtin.fmt.cx(y);
            const y_root = "f_" ++ y_s ++ ".zig";
            const y_root_c = "f_" ++ y_s ++ ".c";
            const y_node: *Node = toplevel.addBuild(allocator, .{ .kind = .obj }, y_s, "test/stress/" ++ y_root);
            const y_node_c: *Node = toplevel.addBuild(allocator, .{ .kind = .obj }, y_s ++ "_c", "test/stress/" ++ y_root_c);
            try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, y_root, text ++ "export fn func_" ++ y_s ++ "() void {}");
            try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, y_root_c, "void c_func_" ++ y_s ++ "() {}");
            y_node.flags.is_hidden = true;
            y_node_c.flags.is_hidden = true;
            x_node.dependOnObject(allocator, y_node);
            x_node.dependOnObject(allocator, y_node_c);
            inline for (0..10) |z| {
                const z_s = y_s ++ comptime builtin.fmt.cx(z);
                const z_root = "f_" ++ z_s ++ ".zig";
                const z_root_c = "f_" ++ z_s ++ ".c";
                const z_node: *Node = toplevel.addBuild(allocator, .{ .kind = .obj }, z_s, "test/stress/" ++ z_root);
                const z_node_c: *Node = toplevel.addBuild(allocator, .{ .kind = .obj }, z_s ++ "_c", "test/stress/" ++ z_root_c);
                try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, z_root, text ++ "export fn func_" ++ z_s ++ "() void {}");
                try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, z_root_c, "void c_func_" ++ z_s ++ "() {}");
                z_node.flags.is_hidden = true;
                z_node_c.flags.is_hidden = true;
                y_node.dependOnObject(allocator, z_node);
                y_node.dependOnObject(allocator, z_node_c);
            }
        }
    }
}
