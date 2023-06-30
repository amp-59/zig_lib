const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const gen = srg.gen;
const sys = srg.sys;
const proc = srg.proc;
const file = srg.file;
const meta = srg.meta;
const build = srg.build;
const builtin = srg.builtin;

pub usingnamespace proc.start;

const Node = build.GenericNode(.{
    .options = .{ .max_thread_count = 8 },
});

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
    try file.makePath(.{}, "test/stress", file.mode.directory);
    const node: *Node = try toplevel.addBuild(allocator, .{ .kind = .exe }, "top", "test/stress/top.zig");
    try gen.truncateFile(.{ .return_type = void }, "test/stress/top.zig", text ++
        \\pub fn main() void {}
    );
    inline for (0..10) |x| {
        const x_s = comptime builtin.fmt.cx(x);
        const x_root = "test/stress/f_" ++ x_s ++ ".zig";
        const x_node: *Node = try toplevel.addBuild(allocator, .{ .kind = .obj }, x_s, x_root);
        x_node.flags.is_hidden = true;
        node.dependOnObject(allocator, x_node);
        try gen.truncateFile(.{ .return_type = void }, x_root, text ++ "export fn func_" ++ x_s ++ "() void {}");
        inline for (0..10) |y| {
            const y_s = x_s ++ comptime builtin.fmt.cx(y);
            const y_root = "test/stress/f_" ++ y_s ++ ".zig";
            const y_node: *Node = try toplevel.addBuild(allocator, .{ .kind = .obj }, y_s, y_root);
            try gen.truncateFile(.{ .return_type = void }, y_root, text ++ "export fn func_" ++ y_s ++ "() void {}");
            y_node.flags.is_hidden = true;
            x_node.dependOn(allocator, y_node, .build);
            inline for (0..10) |z| {
                const z_s = y_s ++ comptime builtin.fmt.cx(z);
                const z_root = "test/stress/f_" ++ z_s ++ ".zig";
                const z_node: *Node = try toplevel.addBuild(allocator, .{ .kind = .obj }, z_s, z_root);
                try gen.truncateFile(.{ .return_type = void }, z_root, text ++ "export fn func_" ++ z_s ++ "() void {}");
                z_node.flags.is_hidden = true;
                y_node.dependOn(allocator, z_node, .build);
            }
        }
    }
}
