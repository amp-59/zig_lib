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
pub const tracing_override: bool = false;
pub const signal_handlers = .{
    .illegal_instruction = false,
    .bus_error = false,
    .floating_point_error = false,
    .breakpoint = false,
    .segmentation_fault = false,
};
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: Node.Allocator = Node.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const toplevel: *Node = Node.init(&allocator, args, vars);
    Node.initSpecialNodes(&allocator, toplevel);
    try meta.wrap(
        root.buildMain(&allocator, toplevel),
    );
    Node.updateCommands(&allocator, toplevel, toplevel);
    try meta.wrap(
        Node.processCommands(&address_space, &thread_space, &allocator, toplevel),
    );
}
