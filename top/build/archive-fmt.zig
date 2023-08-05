const fmt = @import("../fmt.zig");
const build = @import("../build.zig");
const formatters = @import("./formatters.zig");

const render_spec: fmt.RenderSpec = .{ .infer_type_names = true, .forward = true };

export fn formatWriteBufArchiveCommand(ar_cmd: *const build.ArchiveCommand, buf: [*]u8) usize {
    return fmt.render(render_spec, ar_cmd.*).formatWriteBuf(buf);
}
export fn fieldEditDistanceArchive(args: *const struct { s_cmd: *build.ArchiveCommand, t_cmd: *build.ArchiveCommand }) usize {
    return formatters.fieldEditDistance(build.ArchiveCommand, args.s_cmd, args.t_cmd);
}
export fn writeFieldEditsArchive(args: *const struct { buf: [*]u8, node_name: []const u8, s_cmd: *build.ArchiveCommand, t_cmd: *build.ArchiveCommand, commit: bool }) usize {
    return formatters.writeFieldEditDistance(build.ArchiveCommand, args.buf, args.node_name, args.s_cmd, args.t_cmd, args.commit);
}
export fn indexOfCommonLeastDifferenceArchive(args: *const struct { allocator: *build.Allocator, buf: []*build.ArchiveCommand }) usize {
    return formatters.indexOfCommonLeastDifference(build.ArchiveCommand, args.allocator, args.buf);
}
