pub const zl = @import("../../zig_lib.zig");
const proc = zl.proc;
const spec = zl.spec;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;
const Node = build.GenericNode(.{ .errors = .{}, .logging = .{}, .types = .{}, .options = .{
    .show_task_creation = true,
} });
pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) void {
    const save: usize = allocator.next;
    toplevel.descr = "";
    debug.assertAboveOrEqual(usize, allocator.next, save);
}
