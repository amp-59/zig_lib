const root = @import("@build");
const zl = blk: {
    if (@hasDecl(root, "zl")) {
        break :blk root.zl;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "top")) {
        break :blk root.top;
    }
};
const mem = zl.mem;
const sys = zl.sys;
const elf = zl.elf;
const proc = zl.proc;
const meta = zl.meta;
const debug = zl.debug;
const build = zl.build;
const builtin = zl.builtin;
pub usingnamespace zl.start;
pub const Node =
    if (@hasDecl(root, "Node"))
    root.Node
else
    build.GenericNode(.{});
pub const message_style: [:0]const u8 =
    if (@hasDecl(root, "message_style"))
    root.message_style
else
    "\x1b[2m";
pub const logging_override: debug.Logging.Override =
    if (@hasDecl(root, "logging_override")) root.logging_override else .{
    .Attempt = null,
    .Success = null,
    .Acquire = null,
    .Release = null,
    .Error = null,
    .Fault = null,
};
pub const logging_default: debug.Logging.Default = .{
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
pub const want_stack_traces: bool = false;
pub const trace: debug.Trace = .{
    .Error = false,
    .Fault = false,
    .Signal = false,
    .options = .{},
};
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) void {
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));
    if (args.len < 5) {
        proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    try meta.wrap(
        Node.initState(args, vars),
    );
    const toplevel: *Node = try meta.wrap(Node.init(&allocator));
    Node.initSpecialNodes(&allocator, toplevel);
    try meta.wrap(
        root.buildMain(&allocator, toplevel),
    );
    Node.updateCommands(&allocator, toplevel, toplevel);
    try meta.wrap(
        Node.processCommands(&address_space, &thread_space, &allocator, toplevel),
    );
}
