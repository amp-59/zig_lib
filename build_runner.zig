const root = @import("@build");
const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
    if (@hasDecl(root, "top")) {
        break :blk root.top;
    }
};
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const meta = srg.meta;
const build = srg.build;
const builtin = srg.builtin;
pub usingnamespace root;
pub usingnamespace proc.start;
const Node = builtin.define("Node", type, build.GenericNode(.{}));

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
        root.buildMain(&allocator, toplevel),
    );
    Node.updateCommands(&allocator, toplevel, toplevel);
    try meta.wrap(
        Node.processCommands(&address_space, &thread_space, &allocator, toplevel),
    );
}
