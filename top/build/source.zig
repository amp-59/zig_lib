const mach = @import("../mach.zig");
const build = @import("../build.zig");
const builtin = @import("../builtin.zig");

fn rewind(builder: *build.Builder) callconv(.C) void {
    var groups: build.GroupList = builder.groups.itr();
    while (groups.next()) |group_node| : (groups.node = group_node) {
        groups.node.this.targets.head();
    }
}
fn writeAllCommands(builder: *build.Builder, buf: *[1024 * 1024]u8, name_max_width: u64) callconv(.C) u64 {
    var groups: build.GroupList = builder.groups;
    var len: u64 = 0;
    while (@call(.always_inline, build.GroupList.next, .{&groups})) |group_node| : (groups.node = group_node) {
        len +%= builtin.debug.writeMulti(buf[len..], &.{ groups.node.this.name, ":\n" });
        var targets: build.TargetList = groups.node.this.targets;
        while (@call(.always_inline, build.TargetList.next, .{&targets})) |target_node| : (targets.node = target_node) {
            for ("    ", 0..) |c, i| buf[len + i] = c;
            len +%= 4;
            for (targets.node.this.name, 0..) |c, i| buf[len + i] = c;
            len +%= targets.node.this.name.len;
            const count: u64 = name_max_width - targets.node.this.name.len;
            mach.memset(buf[len..].ptr, ' ', count);
            len +%= count;
            for (targets.node.this.root, 0..) |c, i| buf[len + i] = c;
            len +%= targets.node.this.root.len;
            buf[len] = '\n';
            len +%= 1;
        }
    }
    return len;
}
fn maxWidths(builder: *build.Builder) extern struct { u64, u64 } {
    const alignment: u64 = 8;
    var name_max_width: u64 = 0;
    var root_max_width: u64 = 0;
    var groups: build.GroupList = builder.groups;
    while (groups.next()) |group_node| : (groups.node = group_node) {
        var targets: build.TargetList = groups.node.this.targets;
        while (targets.next()) |target_node| : (targets.node = target_node) {
            name_max_width = @max(name_max_width, (targets.node.this.name.len));
            root_max_width = @max(root_max_width, (targets.node.this.root.len));
        }
    }
    name_max_width += alignment;
    root_max_width += alignment;
    return .{ name_max_width & ~(alignment - 1), root_max_width & ~(alignment - 1) };
}
