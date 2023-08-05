const fmt = @import("../fmt.zig");
const build = @import("../build.zig");
const formatters = @import("./formatters.zig");

const render_spec: fmt.RenderSpec = .{ .infer_type_names = true, .forward = true };

export fn formatWriteBufFormatCommand(format_cmd: *const build.FormatCommand, buf: [*]u8) usize {
    return fmt.render(render_spec, format_cmd.*).formatWriteBuf(buf);
}
export fn fieldEditDistanceFormat(args: *const struct { s_cmd: *build.FormatCommand, t_cmd: *build.FormatCommand }) usize {
    return formatters.fieldEditDistance(build.FormatCommand, args.s_cmd, args.t_cmd);
}
export fn writeFieldEditsFormat(args: *const struct { buf: [*]u8, node_name: []const u8, s_cmd: *build.FormatCommand, t_cmd: *build.FormatCommand, commit: bool }) usize {
    return formatters.writeFieldEditDistance(build.FormatCommand, args.buf, args.node_name, args.s_cmd, args.t_cmd, args.commit);
}
export fn indexOfCommonLeastDifferenceFormat(args: *const struct { allocator: *build.Allocator, buf: []*build.FormatCommand }) usize {
    return formatters.indexOfCommonLeastDifference(build.FormatCommand, args.allocator, args.buf);
}
