const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const gen = srg.gen;
const sys = srg.sys;
const proc = srg.proc;
const spec = srg.spec;
const file = srg.file;
const meta = srg.meta;
const build = srg.build;
const builtin = srg.builtin;

pub usingnamespace proc.start;

const Node = build.GenericNode(.{
    .options = .{ .max_thread_count = 8 },
});

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

pub const logging_default: builtin.Logging.Default = .{
    .Attempt = false,
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};
pub const signal_handlers = .{
    .IllegalInstruction = false,
    .BusError = false,
    .FloatingPointError = false,
    .Trap = false,
    .SegmentationFault = false,
};
pub const trace: builtin.Trace = .{
    .Error = false,
    .Fault = false,
    .Signal = false,
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
    const toplevel: *Node = try meta.wrap(Node.init(&allocator, args, vars));
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
    \\const zig_lib = @import("../../zig_lib.zig");
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
    const node: *Node = try toplevel.addBuild(allocator, .{ .kind = .exe }, "top", "test/stress/top.zig");
    try gen.truncateFile(.{ .return_type = void }, "test/stress/top.zig", text ++
        \\pub fn main() void {}
    );
    inline for (0..10) |x| {
        const x_s = comptime builtin.fmt.cx(x);
        const x_root = "f_" ++ x_s ++ ".zig";
        const x_node: *Node = try toplevel.addBuild(allocator, .{ .kind = .obj }, x_s, "test/stress/" ++ x_root);
        x_node.flags.is_hidden = true;
        node.dependOnObject(allocator, x_node);

        try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, x_root, text ++ "export fn func_" ++ x_s ++ "() void {}");
        inline for (0..10) |y| {
            const y_s = x_s ++ comptime builtin.fmt.cx(y);
            const y_root = "f_" ++ y_s ++ ".zig";
            const y_node: *Node = try toplevel.addBuild(allocator, .{ .kind = .obj }, y_s, "test/stress/" ++ y_root);
            try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, y_root, text ++ "export fn func_" ++ y_s ++ "() void {}");
            y_node.flags.is_hidden = true;
            x_node.dependOn(allocator, y_node, .build);
            inline for (0..10) |z| {
                const z_s = y_s ++ comptime builtin.fmt.cx(z);
                const z_root = "f_" ++ z_s ++ ".zig";
                const z_node: *Node = try toplevel.addBuild(allocator, .{ .kind = .obj }, z_s, "test/stress/" ++ z_root);
                try gen.truncateFileAt(.{ .return_type = void }, stress_dir_fd, z_root, text ++ "export fn func_" ++ z_s ++ "() void {}");
                z_node.flags.is_hidden = true;
                y_node.dependOn(allocator, z_node, .build);
            }
        }
    }
}
