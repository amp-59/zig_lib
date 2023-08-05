const fmt = @import("../fmt.zig");
const build = @import("../build.zig");
const render_spec: fmt.RenderSpec = .{ .infer_type_names = true };
pub fn _start() void {}
export fn formatWriteBufObjcopyCommand(objcopy_cmd: *const build.ObjcopyCommand, buf: [*]u8) usize {
    return fmt.render(render_spec, objcopy_cmd.*).formatWriteBuf(buf);
}
export fn fieldEditDistanceObjcopy(args: *const struct { s_cmd: *build.ObjcopyCommand, t_cmd: *build.ObjcopyCommand }) usize {
    return build.GenericCommand(build.ObjcopyCommand)
        .fieldEditDistance(args.s_cmd, args.t_cmd);
}
export fn writeFieldEditsObjcopy(args: *const struct { buf: [*]u8, node_name: []const u8, s_cmd: *build.ObjcopyCommand, t_cmd: *build.ObjcopyCommand, commit: bool }) usize {
    return build.GenericCommand(build.ObjcopyCommand)
        .writeFieldEditDistance(args.buf, args.node_name, args.s_cmd, args.t_cmd, args.commit);
}
export fn indexOfCommonLeastDifferenceObjcopy(args: *const struct { allocator: *build.Allocator, buf: []*build.ObjcopyCommand }) usize {
    return build.GenericCommand(build.ObjcopyCommand)
        .indexOfCommonLeastDifference(args.allocator, args.buf);
}
