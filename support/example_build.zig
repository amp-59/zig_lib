//! Example build program:
pub const zl = @import("./zig_lib/zig_lib.zig");

const build = zl.build;
const Node = build.GenericNode(.{});

const build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .strip = true,
    .compiler_rt = false,
};

pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) void {
    const main: *Node = toplevel.addBuild(allocator, build_cmd, "main", "src/main.zig");
    main.descr = "Build the program.";
}
