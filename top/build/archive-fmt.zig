const fmt = @import("../fmt.zig");
const build = @import("../build.zig");
const render_spec: fmt.RenderSpec = .{ .infer_type_names = true };
pub fn _start() void {}
export fn formatWriteBufArchiveCommand(ar_cmd: *const build.ArchiveCommand, buf: [*]u8) usize {
    return fmt.render(render_spec, ar_cmd.*).formatWriteBuf(buf);
}
export fn fieldEditDistanceArchive(args: *const struct { s_cmd: *build.ArchiveCommand, t_cmd: *build.ArchiveCommand }) usize {
    return build.GenericCommand(build.ArchiveCommand)
        .fieldEditDistance(args.s_cmd, args.t_cmd);
}
export fn writeFieldEditsArchive(args: *const struct { buf: [*]u8, node_name: []const u8, s_cmd: *build.ArchiveCommand, t_cmd: *build.ArchiveCommand, commit: bool }) usize {
    return build.GenericCommand(build.ArchiveCommand)
        .writeFieldEditDistance(args.buf, args.node_name, args.s_cmd, args.t_cmd, args.commit);
}
export fn indexOfCommonLeastDifferenceArchive(args: *const struct { allocator: *build.Allocator, buf: []*build.ArchiveCommand }) usize {
    return build.GenericCommand(build.ArchiveCommand)
        .indexOfCommonLeastDifference(args.allocator, args.buf);
}
