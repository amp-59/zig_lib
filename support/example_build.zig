//! Example build program:
pub const zl = @import("./zig_lib/zig_lib.zig");

const build = zl.build;
const Node = build.GenericNode(.{});

pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) void {
    const main: *Node = toplevel.addBuild(allocator, .{ .kind = .exe, .strip = true }, "main", "src/main.zig");
    main.descr = "Build the program.";
}
