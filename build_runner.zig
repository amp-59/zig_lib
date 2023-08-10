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
pub const enable_debugging: bool =
    if (@hasDecl(root, "enable_debugging"))
    root.enable_debugging
else
    false;
pub const logging_override: debug.Logging.Override =
    if (@hasDecl(root, "logging_override")) root.logging_override else .{
    .Attempt = null,
    .Success = null,
    .Acquire = null,
    .Release = null,
    .Error = null,
    .Fault = null,
};
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
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) void {
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: build.Allocator = build.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));
    if (args.len < 5) {
        proc.exitError(error.MissingEnvironmentPaths, 2);
    }
    const toplevel: *Node = Node.init(&allocator, args, vars);
    toplevel.addSpecialNodes(&allocator);
    try meta.wrap(
        root.buildMain(&allocator, toplevel),
    );
    Node.updateCommands(&allocator, toplevel);
    try meta.wrap(
        Node.processCommands(&address_space, &thread_space, &allocator, toplevel),
    );
}
