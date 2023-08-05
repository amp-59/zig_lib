const fmt = @import("../fmt.zig");
const build = @import("../build.zig");
const formatters = @import("./formatters.zig");

const render_spec: fmt.RenderSpec = .{ .infer_type_names = true, .forward = true };

export fn formatWriteBufBuildCommand(build_cmd: *const build.BuildCommand, buf: [*]u8) usize {
    return fmt.render(render_spec, build_cmd.*).formatWriteBuf(buf);
}
export fn fieldEditDistanceBuild(args: *const struct { s_cmd: *build.BuildCommand, t_cmd: *build.BuildCommand }) usize {
    return formatters.fieldEditDistance(build.BuildCommand, args.s_cmd, args.t_cmd);
}
export fn writeFieldEditsBuild(args: *const struct { buf: [*]u8, node_name: []const u8, s_cmd: *build.BuildCommand, t_cmd: *build.BuildCommand, commit: bool }) usize {
    return formatters.writeFieldEditDistance(build.BuildCommand, args.buf, args.node_name, args.s_cmd, args.t_cmd, args.commit);
}
export fn indexOfCommonLeastDifferenceBuild(args: *const struct { allocator: *build.Allocator, buf: []*build.BuildCommand }) usize {
    return formatters.indexOfCommonLeastDifference(build.BuildCommand, args.allocator, args.buf);
}
