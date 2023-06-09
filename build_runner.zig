const root = @import("@build");
const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const meta = srg.meta;
const spec = srg.spec;
const build = srg.build;
const builtin = srg.builtin;

pub usingnamespace root;
pub usingnamespace proc.start;

const Node = if (@hasDecl(root, "Node")) root.Node else build.GenericNode(.{});

pub const is_debug: bool = false;

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Node.AddressSpace = .{};
    var thread_space: Node.ThreadSpace = .{};
    var allocator: Node.Allocator = if (Node.Allocator == mem.SimpleAllocator)
        Node.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count))
    else
        Node.Allocator.init(&address_space, Node.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const toplevel: *Node = Node.init(&allocator, args, vars);
    try meta.wrap(
        root.buildMain(&allocator, toplevel),
    );
    try meta.wrap(
        Node.processCommands(&address_space, &thread_space, &allocator, toplevel),
    );
}
