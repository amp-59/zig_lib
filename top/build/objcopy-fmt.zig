const fmt = @import("../fmt.zig");
const build = @import("../build.zig");
const formatters = @import("./formatters.zig");

const render_spec: fmt.RenderSpec = .{ .infer_type_names = true, .forward = true };

export fn formatWriteBufObjcopyCommand(objcopy_cmd: *const build.ObjcopyCommand, buf: [*]u8) usize {
    return fmt.render(render_spec, objcopy_cmd.*).formatWriteBuf(buf);
}
export fn fieldEditDistanceObjcopy(args: *const struct { s_cmd: *build.ObjcopyCommand, t_cmd: *build.ObjcopyCommand }) usize {
    return formatters.fieldEditDistance(build.ObjcopyCommand, args.s_cmd, args.t_cmd);
}
export fn writeFieldEditsObjcopy(args: *const struct { buf: [*]u8, node_name: []const u8, s_cmd: *build.ObjcopyCommand, t_cmd: *build.ObjcopyCommand, commit: bool }) usize {
    return formatters.writeFieldEditDistance(build.ObjcopyCommand, args.buf, args.node_name, args.s_cmd, args.t_cmd, args.commit);
}
export fn indexOfCommonLeastDifferenceObjcopy(args: *const struct { allocator: *build.Allocator, buf: []*build.ObjcopyCommand }) usize {
    return formatters.indexOfCommonLeastDifference(build.ObjcopyCommand, args.allocator, args.buf);
}
